class Api::V1::MessagesController < ApplicationController
  before_action :authorize
  before_action :set_project

  # GET /api/v1/projects/:project_id/messages
  def index
    @messages = @project.messages.order(created_at: :asc)
    
    render json: {
      project_id: @project.id,
      messages: @messages.map { |m| 
        {
          id: m.id,
          role: m.role,
          content: m.content,
          attachments: m.files.map.with_index { |file, idx| 
            {
              id: file.id,
              file_id: m.file_ids.present? ? m.file_ids[idx] : nil,
              filename: file.filename.to_s,
              content_type: file.content_type,
              byte_size: file.byte_size,
              url: rails_blob_path(file, only_path: true)
            }
          },
          created_at: m.created_at
        }
      }
    }
  end

  # POST /api/v1/projects/:project_id/messages
  def create
    # Validate model parameter
    model = message_params[:model] || 'claude-sonnet-4-5'
    unless valid_model?(model)
      return render json: { 
        error: "Invalid model. Choose from: claude-sonnet-4-5, claude-opus-4" 
      }, status: :unprocessable_entity
    end
    
    # Map friendly names to full model names
    full_model_name = map_model_name(model)
    
    # Handle file uploads if present
    uploaded_file_ids = []
    uploaded_files_for_storage = []
    message_content = message_params[:content]
    
    if params[:files].present?
      files_service = ClaudeFilesService.new
  
      # Check if code execution is enabled (default: true)
      enable_code_execution = params.fetch(:enable_code_execution, 'true').to_s.downcase == 'true'
  
      # Ensure files is always an array (handles both single file and multiple files)
      files_array = params[:files].is_a?(Array) ? params[:files] : [params[:files]]
  
      files_array.each do |file|
        begin
          # Save file temporarily
          temp_path = Rails.root.join('tmp', 'uploads', file.original_filename)
          FileUtils.mkdir_p(File.dirname(temp_path))
          File.open(temp_path, 'wb') do |f|
            f.write(file.read)
          end
          
          mime_type = file.content_type
          block_type = files_service.get_content_block_type(mime_type)
          
          # For code execution, always upload CSV files to Files API
          # For non-code-execution mode, convert to text
          if enable_code_execution && mime_type == 'text/csv'
            # Upload CSV to Files API for code execution
            upload_result = files_service.upload_file(temp_path, mime_type)
            uploaded_file_ids << upload_result['id']
            # Keep file for local storage
            uploaded_files_for_storage << { path: temp_path, filename: file.original_filename, content_type: mime_type }
          elsif block_type == 'convert_to_text'
            # For Word/Excel files or when code execution is disabled, convert to text
            text_content = files_service.convert_document_to_text(temp_path, mime_type)
            message_content = "#{message_content}\n\n[Attached file: #{file.original_filename}]\n#{text_content}"
            # Keep file for local storage
            uploaded_files_for_storage << { path: temp_path, filename: file.original_filename, content_type: mime_type }
          else
            # For PDFs and images, upload to Claude Files API
            upload_result = files_service.upload_file(temp_path, mime_type)
            uploaded_file_ids << upload_result['id']
            # Keep file for local storage
            uploaded_files_for_storage << { path: temp_path, filename: file.original_filename, content_type: mime_type }
          end
        rescue => e
          return render json: { error: "File upload failed: #{e.message}" }, status: :unprocessable_entity
        end
      end
    end
    
    # Create user message with file attachments
    user_message = @project.messages.create!(
      role: 'user',
      content: message_content,
      file_ids: uploaded_file_ids
    )
    
    # Attach files to Active Storage for permanent storage
    uploaded_files_for_storage.each do |file_info|
      user_message.files.attach(
        io: File.open(file_info[:path]),
        filename: file_info[:filename],
        content_type: file_info[:content_type]
      )
      # Clean up temp file after attaching
      File.delete(file_info[:path]) if File.exist?(file_info[:path])
    end
    
    # Get conversation history with file IDs
    # Exclude the current user message that was just created to avoid duplication
    # Only include file IDs for recent messages (within 7 days) to avoid expired file issues
    seven_days_ago = 7.days.ago
    conversation_history = @project.messages.where.not(id: user_message.id).order(created_at: :asc).map do |msg|
      history_msg = { role: msg.role, content: msg.content }
      # Only include file_ids for USER messages (not assistant messages)
      # Assistant file_ids are for generated files and shouldn't be re-sent to Claude
      if msg.role == 'user' && msg.file_ids.present? && msg.created_at > seven_days_ago
        history_msg[:file_ids] = msg.file_ids
      end
      history_msg
    end
    
    # Ensure messages alternate between user and assistant (Claude API requirement)
    # Merge consecutive messages from the same role
    normalized_history = []
    conversation_history.each do |msg|
      if normalized_history.empty? || normalized_history.last[:role] != msg[:role]
        normalized_history << msg
      else
        # Merge consecutive same-role messages by combining content
        last_msg = normalized_history.last
        last_msg[:content] = "#{last_msg[:content]}\n\n#{msg[:content]}"
        # Keep file_ids from both messages if present
        if msg[:file_ids].present?
          last_msg[:file_ids] ||= []
          last_msg[:file_ids] += msg[:file_ids]
        end
      end
    end
    
    # Add the current user message at the end
    current_msg = { role: 'user', content: message_content }
    if uploaded_file_ids.present?
      current_msg[:file_ids] = uploaded_file_ids
    end
    
    # If the last message in history is also 'user', merge with current message
    if normalized_history.any? && normalized_history.last[:role] == 'user'
      last_msg = normalized_history.last
      last_msg[:content] = "#{last_msg[:content]}\n\n#{current_msg[:content]}"
      if current_msg[:file_ids].present?
        last_msg[:file_ids] ||= []
        last_msg[:file_ids] += current_msg[:file_ids]
      end
      conversation_history = normalized_history
    else
      conversation_history = normalized_history + [current_msg]
    end
    
    # Call Claude AI service
    begin
      claude_service = ClaudeService.new
      
      # Check if container_id is provided for reuse
      options = {}
      if params[:container_id].present?
        options[:container_id] = params[:container_id]
      end
      
      # Code execution is enabled by default; can be disabled via params
      options[:enable_code_execution] = params.fetch(:enable_code_execution, true)
      
      result = claude_service.generate_content(conversation_history, full_model_name, options)
      
      # Extract generated file IDs
      generated_file_ids = result[:generated_files].map { |f| f[:file_id] }
      
      # Save assistant message with generated files
      assistant_message = @project.messages.create!(
        role: 'assistant',
        content: result[:text],
        file_ids: generated_file_ids
      )
      
      # Download and attach generated files to Active Storage
      if generated_file_ids.present?
        files_service = ClaudeFilesService.new
        generated_file_ids.each do |file_id|
          begin
            # Download file from Claude
            file_content = files_service.download_file(file_id)
            file_metadata = files_service.get_file_metadata(file_id)
            
            # Save to temporary file
            temp_path = Rails.root.join('tmp', 'downloads', file_metadata['filename'])
            FileUtils.mkdir_p(File.dirname(temp_path))
            File.open(temp_path, 'wb') { |f| f.write(file_content) }
            
            # Attach to message
            assistant_message.files.attach(
              io: File.open(temp_path),
              filename: file_metadata['filename'],
              content_type: file_metadata['mime_type']
            )
            
            # Clean up
            File.delete(temp_path) if File.exist?(temp_path)
          rescue => e
            Rails.logger.error "Failed to download generated file #{file_id}: #{e.message}"
          end
        end
      end
      
      render json: {
        user_message: {
          id: user_message.id,
          role: user_message.role,
          content: user_message.content,
          attachments: user_message.files.map.with_index { |file, idx| 
            {
              id: file.id,
              file_id: user_message.file_ids.present? ? user_message.file_ids[idx] : nil,
              filename: file.filename.to_s,
              content_type: file.content_type,
              byte_size: file.byte_size,
              url: rails_blob_path(file, only_path: true)
            }
          },
          created_at: user_message.created_at
        },
        assistant_message: {
          id: assistant_message.id,
          role: assistant_message.role,
          content: assistant_message.content,
          attachments: assistant_message.files.map.with_index { |file, idx| 
            {
              id: file.id,
              file_id: assistant_message.file_ids.present? ? assistant_message.file_ids[idx] : nil,
              filename: file.filename.to_s,
              content_type: file.content_type,
              byte_size: file.byte_size,
              url: rails_blob_path(file, only_path: true)
            }
          },
          created_at: assistant_message.created_at
        },
        container_id: result[:container_id],
        model_used: model
      }, status: :created
    rescue => e
      render json: { error: "Failed to generate response: #{e.message}" }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/projects/:project_id/messages/uploaded_files
  def uploaded_files
    all_uploaded_files = []
    
    @project.messages.where(role: 'user').order(created_at: :asc).each do |message|
      next if message.files.blank?
      
      message.files.each_with_index do |file, idx|
        all_uploaded_files << {
          id: file.id,
          file_id: message.file_ids.present? ? message.file_ids[idx] : nil,
          filename: file.filename.to_s,
          content_type: file.content_type,
          byte_size: file.byte_size,
          url: rails_blob_path(file, only_path: true),
          message_id: message.id,
          uploaded_at: message.created_at
        }
      end
    end
    
    render json: {
      project_id: @project.id,
      total_count: all_uploaded_files.size,
      uploaded_files: all_uploaded_files
    }
  end

  # GET /api/v1/projects/:project_id/messages/generated_files
  def generated_files
    all_generated_files = []
    
    @project.messages.where(role: 'assistant').order(created_at: :asc).each do |message|
      next if message.files.blank?
      
      message.files.each_with_index do |file, idx|
        all_generated_files << {
          id: file.id,
          file_id: message.file_ids.present? ? message.file_ids[idx] : nil,
          filename: file.filename.to_s,
          content_type: file.content_type,
          byte_size: file.byte_size,
          url: rails_blob_path(file, only_path: true),
          message_id: message.id,
          generated_at: message.created_at
        }
      end
    end
    
    render json: {
      project_id: @project.id,
      total_count: all_generated_files.size,
      generated_files: all_generated_files
    }
  end

  # DELETE /api/v1/projects/:project_id/messages
  def destroy
    @project.messages.destroy_all
    render json: { message: 'All messages deleted successfully' }, status: :ok
  end

  private

  def set_project
    @project = @user.projects.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Project not found' }, status: :not_found
  end

  def message_params
    params.require(:message).permit(:content, :model)
  end
  
  def valid_model?(model)
    %w[claude-sonnet-4-5 claude-opus-4].include?(model)
  end
  
  def map_model_name(friendly_name)
    model_map = {
      'claude-sonnet-4-5' => 'claude-sonnet-4-5-20250929',
      'claude-opus-4' => 'claude-opus-4-20250514'
    }
    model_map[friendly_name] || friendly_name
  end
end

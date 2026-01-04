require 'net/http'
require 'json'

class ClaudeService
  API_URL = 'https://api.anthropic.com/v1/messages'
  API_VERSION = '2023-06-01'
  # Multiple beta versions: files API + code execution
  BETA_VERSION = 'code-execution-2025-08-25,files-api-2025-04-14'
  
  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    raise 'ANTHROPIC_API_KEY not set' unless @api_key
  end
  
  # Generate content with optional file attachments and code execution
  # messages: array of {role:, content:, file_ids: (optional), file_metadata: (optional)}
  # options: {container_id: (optional), enable_code_execution: true/false (default: true)}
  def generate_content(messages, model = 'claude-sonnet-4-5-20250929', options = {})
    uri = URI(API_URL)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    # Increase timeouts for code execution (can take longer)
    http.open_timeout = 30      # Time to establish connection
    http.read_timeout = 300     # Time to wait for response (5 minutes)
    http.write_timeout = 30     # Time to send request
    
    request = Net::HTTP::Post.new(uri)
    request['x-api-key'] = @api_key
    request['anthropic-version'] = API_VERSION
    request['anthropic-beta'] = BETA_VERSION
    request['content-type'] = 'application/json'
    
    body = {
      model: model,
      max_tokens: 8192, # Increased for document processing
      messages: format_messages(messages)
    }
    
    # Add code execution tool (enabled by default)
    enable_code_execution = options.fetch(:enable_code_execution, true)
    if enable_code_execution
      body[:tools] = [{
        type: 'code_execution_20250825',
        name: 'code_execution'
      }]
    end
    
    # Add container ID for reusing containers
    if options[:container_id].present?
      body[:container] = options[:container_id]
    end
    
    request.body = body.to_json
    
    # Log request for debugging
    Rails.logger.info "Claude API Request - Model: #{model}, Code Execution: #{enable_code_execution}, Container: #{options[:container_id] || 'new'}"
    Rails.logger.debug "Claude API Request Body: #{body.to_json}"
    
    begin
      response = http.request(request)
      
      if response.code == '200'
        result = JSON.parse(response.body)
        
        # Debug logging to see full response structure
        Rails.logger.debug "Claude API Full Response: #{result.to_json}"
        
        # Extract generated file IDs from code execution results
        generated_files = extract_generated_files(result)
        
        # Return full response including container_id and generated files
        {
          text: extract_text_from_response(result),
          container_id: result.dig('container', 'id'),
          generated_files: generated_files,
          full_response: result
        }
      else
        Rails.logger.error "Claude API Error: #{response.code} - #{response.body}"
        raise "Claude API error: #{response.code} - #{response.body}"
      end
    rescue Net::OpenTimeout => e
      Rails.logger.error "Claude API Connection Timeout: #{e.message}"
      raise "Connection timeout - Claude API took too long to connect: #{e.message}"
    rescue Net::ReadTimeout => e
      Rails.logger.error "Claude API Read Timeout: #{e.message}"
      raise "Response timeout - Claude is still processing. For long operations, consider increasing timeout or checking container status."
    rescue StandardError => e
      Rails.logger.error "Claude API Error: #{e.class} - #{e.message}"
      raise
    end
  end
  
  private
  
  def format_messages(messages)
    messages.map do |msg|
      content = build_content_blocks(msg)
      
      # Skip messages with empty content
      next if content.blank? || (content.is_a?(Array) && content.empty?)
      
      formatted_msg = {
        role: msg[:role],
        content: content
      }
      formatted_msg
    end.compact # Remove nil entries
  end
  
  # Build content blocks (text + optional files)
  # When code execution is enabled with files, use container_upload for better integration
  def build_content_blocks(msg)
    content_blocks = []
    
    # Add text content
    if msg[:content].present?
      content_blocks << {
        type: 'text',
        text: msg[:content]
      }
    end
    
    # Add file attachments if present
    # Note: Only include files for the current/recent messages to avoid issues with expired file IDs
    if msg[:file_ids].present? && msg[:file_ids].any?
      msg[:file_ids].each do |file_id|
        next if file_id.blank? # Skip nil/empty file IDs
        
        # Use container_upload for code execution compatibility
        # This allows Claude to directly access files in the code execution environment
        content_blocks << {
          type: 'container_upload',
          file_id: file_id
        }
      end
    end
    
    # If no content blocks were added, return empty string to avoid API errors
    return '' if content_blocks.empty?
    
    # If only one text block, return just the text string for simpler API format
    if content_blocks.size == 1 && content_blocks[0][:type] == 'text'
      return content_blocks[0][:text]
    end
    
    # Return array if multiple blocks or if there are files
    content_blocks
  end
  
  def extract_text_from_response(result)
    # With code execution, response can have multiple content blocks:
    # - text blocks
    # - tool_use blocks (code execution)
    # - tool_result blocks (execution output)
    # We need to combine them all into a readable response
    
    content_blocks = result['content'] || []
    return 'No response generated' if content_blocks.empty?
    
    response_parts = []
    
    content_blocks.each do |block|
      case block['type']
      when 'text'
        # Regular text response
        response_parts << block['text'] if block['text'].present?
        
      when 'server_tool_use'
        # Code execution tool use - show what Claude is doing
        if block['name'] == 'bash_code_execution'
          command = block.dig('input', 'command')
          response_parts << "\n```bash\n#{command}\n```" if command
        elsif block['name'] == 'text_editor_code_execution'
          # File operations
          cmd = block.dig('input', 'command')
          path = block.dig('input', 'path')
          response_parts << "\n[File operation: #{cmd} #{path}]" if cmd && path
        end
        
      when 'bash_code_execution_tool_result'
        # Results from bash/code execution
        content = block['content']
        if content && content['type'] == 'bash_code_execution_result'
          stdout = content['stdout']
          stderr = content['stderr']
          response_parts << "\n```\n#{stdout}\n```" if stdout.present?
          response_parts << "\nError: #{stderr}" if stderr.present?
        end
        
      when 'text_editor_code_execution_tool_result'
        # Results from file operations
        content = block['content']
        if content && content['type'] == 'text_editor_code_execution_result'
          # Show file content if viewing
          file_content = content['content']
          response_parts << "\n```\n#{file_content}\n```" if file_content.present?
        end
      end
    end
    
    response_parts.join("\n\n").strip
  end
  
  def extract_generated_files(result)
    # Extract file IDs from bash_code_execution_tool_result blocks
    generated_files = []
    
    content_blocks = result['content'] || []
    content_blocks.each do |block|
      # Look for bash execution results
      if block['type'] == 'bash_code_execution_tool_result'
        content = block['content']
        
        # The content structure for code execution results:
        # {
        #   "type": "bash_code_execution_result",
        #   "stdout": "...",
        #   "stderr": "...", 
        #   "return_code": 0,
        #   "content": [  # <- exported files are here
        #     {
        #       "type": "file",
        #       "file_id": "file_xyz",
        #       "filename": "plot.png"
        #     }
        #   ]
        # }
        
        if content.is_a?(Hash)
          # Check if there's a content array with files
          files = content['content']
          
          if files.is_a?(Array)
            files.each do |file_item|
              if file_item.is_a?(Hash)
                # Handle both 'file' type and 'bash_code_execution_output' type
                if (file_item['type'] == 'file' || file_item['type'] == 'bash_code_execution_output') && file_item['file_id']
                  generated_files << {
                    file_id: file_item['file_id'],
                    filename: file_item['filename'] || 'generated_file'
                  }
                end
              end
            end
          end
        end
      end
      
      # Also check text_editor results for file references
      if block['type'] == 'text_editor_code_execution_tool_result'
        content = block['content']
        if content.is_a?(Hash) && content['type'] == 'text_editor_code_execution_result'
          # Check if file was created/edited and has a file_id
          if content['file_id'].present?
            generated_files << {
              file_id: content['file_id'],
              filename: content['filename'] || block.dig('input', 'path') || 'generated_file'
            }
          end
        end
      end
    end
    
    # Log for debugging
    Rails.logger.info "Extracted #{generated_files.length} generated files: #{generated_files.inspect}"
    
    generated_files
  end
end

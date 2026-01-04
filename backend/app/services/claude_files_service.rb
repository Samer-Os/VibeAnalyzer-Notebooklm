require 'net/http'
require 'json'

class ClaudeFilesService
  BASE_URL = "https://api.anthropic.com/v1/files"
  API_VERSION = "2023-06-01"
  BETA_VERSION = "files-api-2025-04-14"
  
  # Supported MIME types for Claude Files API
  SUPPORTED_MIME_TYPES = {
    'application/pdf' => 'document',
    'text/plain' => 'document',
    'text/csv' => 'document',  # Changed: CSV now uploads as document for code execution
    'image/jpeg' => 'image',
    'image/png' => 'image',
    'image/gif' => 'image',
    'image/webp' => 'image',
    # Document types that need conversion to text (Word, Excel)
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'convert_to_text', # .docx
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'convert_to_text', # .xlsx
    'application/msword' => 'convert_to_text', # .doc
    'application/vnd.ms-excel' => 'convert_to_text' # .xls
  }
  
  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
    raise "ANTHROPIC_API_KEY environment variable is not set" unless @api_key
  end
  
  # Upload a file to Claude Files API
  # Returns file_id and metadata
  def upload_file(file_path, mime_type)
    unless SUPPORTED_MIME_TYPES.key?(mime_type)
      raise "Unsupported file type: #{mime_type}"
    end
    
    # Check file size (max 500 MB)
    file_size = File.size(file_path)
    if file_size > 500 * 1024 * 1024
      raise "File too large. Maximum size is 500 MB"
    end
    
    uri = URI(BASE_URL)
    request = Net::HTTP::Post.new(uri)
    request['x-api-key'] = @api_key
    request['anthropic-version'] = API_VERSION
    request['anthropic-beta'] = BETA_VERSION
    
    # Create multipart form data
    boundary = "----WebKitFormBoundary#{SecureRandom.hex(16)}"
    request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
    
    file_content = File.binread(file_path)
    filename = File.basename(file_path)
    
    body = []
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
    body << "Content-Type: #{mime_type}\r\n\r\n"
    body << file_content
    body << "\r\n--#{boundary}--\r\n"
    
    request.body = body.join
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "File upload failed: #{response.code} - #{response.body}"
    end
  end
  
  # List all uploaded files
  def list_files
    uri = URI(BASE_URL)
    request = Net::HTTP::Get.new(uri)
    request['x-api-key'] = @api_key
    request['anthropic-version'] = API_VERSION
    request['anthropic-beta'] = BETA_VERSION
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "Failed to list files: #{response.code} - #{response.body}"
    end
  end
  
  # Get file metadata
  def get_file_metadata(file_id)
    uri = URI("#{BASE_URL}/#{file_id}")
    request = Net::HTTP::Get.new(uri)
    request['x-api-key'] = @api_key
    request['anthropic-version'] = API_VERSION
    request['anthropic-beta'] = BETA_VERSION
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "Failed to get file metadata: #{response.code} - #{response.body}"
    end
  end
  
  # Delete a file
  def delete_file(file_id)
    uri = URI("#{BASE_URL}/#{file_id}")
    request = Net::HTTP::Delete.new(uri)
    request['x-api-key'] = @api_key
    request['anthropic-version'] = API_VERSION
    request['anthropic-beta'] = BETA_VERSION
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      raise "Failed to delete file: #{response.code} - #{response.body}"
    end
  end
  
  # Download a file's content
  def download_file(file_id)
    uri = URI("#{BASE_URL}/#{file_id}/content")
    request = Net::HTTP::Get.new(uri)
    request['x-api-key'] = @api_key
    request['anthropic-version'] = API_VERSION
    request['anthropic-beta'] = BETA_VERSION
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      response.body # Return binary content
    else
      raise "Failed to download file: #{response.code} - #{response.body}"
    end
  end
  
  # Determine content block type based on MIME type
  def get_content_block_type(mime_type)
    SUPPORTED_MIME_TYPES[mime_type]
  end
  
  # Convert document files (Word, Excel) to text content
  def convert_document_to_text(file_path, mime_type)
    case mime_type
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      extract_docx_text(file_path)
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      extract_xlsx_text(file_path)
    when 'text/csv'
      File.read(file_path)
    else
      raise "Cannot convert #{mime_type} to text"
    end
  end
  
  private
  
  def extract_docx_text(file_path)
    require 'zip'
    
    text = ""
    Zip::File.open(file_path) do |zip_file|
      entry = zip_file.find_entry('word/document.xml')
      if entry
        content = entry.get_input_stream.read
        # Remove XML tags to get plain text
        text = content.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
      end
    end
    text
  end
  
  def extract_xlsx_text(file_path)
    require 'creek'
    
    text = ""
    workbook = Creek::Book.new(file_path)
    workbook.sheets.each do |sheet|
      sheet.rows.each do |row|
        text += row.values.join("\t") + "\n"
      end
    end
    text
  rescue => e
    # Fallback: just mention it's an Excel file
    "Excel file: #{File.basename(file_path)}"
  end
end

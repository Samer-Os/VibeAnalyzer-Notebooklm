class ReportGenerationJob < ApplicationJob
  queue_as :default

  def perform(report_id)
    report = Report.find(report_id)
    report.update(status: 'processing')

    begin
      # Logic to generate report
      # For now, we'll just simulate it or call a service
      # In a real app, this might aggregate data from messages/projects
      
      # content = GenerateReportService.new(report.project).call
      content = "Report generated for Project #{report.project.name} at #{Time.current}"
      
      report.update(content: content, status: 'completed')
    rescue => e
      report.update(status: 'failed')
      Rails.logger.error "Report generation failed: #{e.message}"
    end
  end
end

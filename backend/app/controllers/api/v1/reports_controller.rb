module Api
  module V1
    class ReportsController < ApplicationController
      before_action :authorize
      before_action :set_project
      before_action :set_report, only: [:show, :destroy]

      def index
        page = (params[:page] || 1).to_i
        per_page = [[params[:per_page].to_i, 1].max, 100].min
        per_page = 20 if per_page == 0
        
        reports = Report.joins(:message).where(messages: { project_id: @project.id })
        total_count = reports.count
        total_pages = (total_count.to_f / per_page).ceil
        
        paginated_reports = reports.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)
        
        render json: {
          project_id: @project.id,
          total_count: total_count,
          current_page: page,
          per_page: per_page,
          total_pages: total_pages,
          reports: paginated_reports.map { |r| serialize_report(r) }
        }
      end

      def show
        render json: serialize_report(@report)
      end

      def create
        message = @project.messages.find(report_params[:message_id])
        
        # Check if report already exists
        if message.report
          render json: serialize_report(message.report).merge(notice: "A report already exists for this message. Returning existing report."), status: :ok
          return
        end

        @report = message.build_report(
          report_type: report_params[:report_type],
          metadata: report_params[:metadata].is_a?(String) ? JSON.parse(report_params[:metadata]) : report_params[:metadata],
          status: 'ready',
          title: @project.name
        )
        
        if params[:pdf_file]
          @report.pdf_file.attach(params[:pdf_file])
        end
        
        if params[:zip_file]
          @report.zip_file.attach(params[:zip_file])
        end

        if @report.save
          render json: serialize_report(@report), status: :created
        else
          render json: { error: "Validation failed", details: @report.errors }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Validation failed", details: { message_id: ["Message not found or does not belong to this project"] } }, status: :unprocessable_entity
      rescue JSON::ParserError
        render json: { error: "Validation failed", details: { metadata: ["Invalid JSON format"] } }, status: :unprocessable_entity
      end

      def destroy
        @report.destroy
        render json: { message: "Report deleted successfully" }
      end
      
      private
      
      def set_project
        @project = @user.projects.find(params[:project_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      def set_report
        @report = Report.joins(:message).where(messages: { project_id: @project.id }).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Report not found" }, status: :not_found
      end
      
      def report_params
        params.require(:report).permit(:message_id, :report_type, :metadata)
      end
      
      def serialize_report(report)
        {
          id: report.id,
          project_id: report.message.project_id,
          message_id: report.message_id,
          user_id: @user.id,
          title: report.title,
          report_type: report.report_type,
          status: report.status,
          file_size_bytes: report.pdf_file.attached? ? report.pdf_file.byte_size : 0,
          metadata: report.metadata,
          pdf_url: report.pdf_file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(report.pdf_file, only_path: true) : nil,
          zip_url: report.zip_file.attached? ? Rails.application.routes.url_helpers.rails_blob_url(report.zip_file, only_path: true) : nil,
          created_at: report.created_at
        }
      end
    end
  end
end

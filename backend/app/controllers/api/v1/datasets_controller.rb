module Api
  module V1
    class DatasetsController < ApplicationController
      before_action :authorize
      before_action :set_dataset, only: [:show, :destroy, :analyze]

      def index
        # In a real app, scope to current_user
        @datasets = Dataset.all
        render json: @datasets
      end

      def show
        render json: @dataset
      end

      def create
        @dataset = Dataset.new(dataset_params)
        # @dataset.user = current_user # TODO: Add auth

        if @dataset.save
          # Trigger background job for analysis
          render json: @dataset, status: :created
        else
          render json: @dataset.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @dataset.destroy
        head :no_content
      end

      def analyze
        # Placeholder for triggering analysis logic
        # This would likely call a service object that inspects the data
        render json: { message: "Analysis started", status: "processing" }
      end

      def all_uploaded_files
        # Retrieve all files uploaded across all user's projects.
        # Files are attached to Messages which belong to Projects which belong to User.
        
        files = ActiveStorage::Attachment.joins(record: { project: :user })
                  .where(users: { id: @user.id })
                  .where(record_type: 'Message')
                  # We might want to filter by role='user' on the message if we only want user uploads
                  # But let's assume all attachments on messages are relevant for now.
        
        render json: {
          uploaded_files: files.map { |f|
            {
              id: f.id,
              file_id: f.blob.key,
              filename: f.filename.to_s,
              content_type: f.content_type,
              byte_size: f.byte_size,
              url: Rails.application.routes.url_helpers.rails_blob_url(f, only_path: true),
              message_id: f.record_id,
              project_id: f.record.project_id,
              uploaded_at: f.created_at
            }
          }
        }
      end

      private

      def set_dataset
        @dataset = Dataset.find(params[:id])
      end

      def dataset_params
        params.require(:dataset).permit(:name, :description) # :file would be handled by ActiveStorage
      end
    end
  end
end

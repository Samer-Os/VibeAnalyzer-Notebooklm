module Api
  module V1
    class ProjectsController < ApplicationController
      before_action :authorize
      before_action :set_project, only: [:show, :update, :destroy]

      def index
        @projects = @user.projects
        render json: @projects
      end

      def create
        @project = @user.projects.build(project_params)
        if @project.save
          render json: @project, status: :created
        else
          render json: @project.errors, status: :unprocessable_entity
        end
      end
      
      def show
        render json: @project
      end

      def update
        if @project.update(project_params)
          render json: @project
        else
          render json: @project.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @project.destroy
        render json: { message: "Project deleted successfully" }
      end

      private

      def set_project
        @project = @user.projects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found or you do not have permission" }, status: :not_found
      end

      def project_params
        params.require(:project).permit(:name, :description)
      end
    end
  end
end

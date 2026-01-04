module Api
  module V1
    class ResearchSessionsController < ApplicationController
      before_action :set_session, only: [:show, :recommend_methods]

      def index
        @sessions = ResearchSession.all
        render json: @sessions
      end

      def show
        render json: @session, include: [:messages, :recommendations]
      end

      def create
        @session = ResearchSession.new(session_params)
        
        if @session.save
          render json: @session, status: :created
        else
          render json: @session.errors, status: :unprocessable_entity
        end
      end

      def recommend_methods
        # This endpoint would trigger the AI logic to generate recommendations
        # based on the session context and dataset.
        
        # Mock response for MVP
        recommendation = @session.recommendations.create!(
          method_name: "Linear Regression",
          description: "A statistical method to model the relationship between a scalar response and one or more explanatory variables.",
          rationale: "Based on your interest in predicting continuous outcomes.",
          evidence: { source: "PubMed", confidence: 0.85 }
        )

        render json: recommendation
      end

      private

      def set_session
        @session = ResearchSession.find(params[:id])
      end

      def session_params
        params.require(:research_session).permit(:title, :dataset_id)
      end
    end
  end
end

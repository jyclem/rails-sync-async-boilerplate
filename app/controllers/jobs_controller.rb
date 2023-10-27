# frozen_string_literal: true

# Handle Sidekiq jobs
class JobsController < ApplicationController
  def show
    # here we do not return sensitive data, so there is no particular authorization for now, but
    # if needed we can use Sidekiq context to make sure to allow access only to the user
    # who triggered the job
    render json: { id: params[:id], status: Sidekiq::Status.status(params[:id]) }, status: :ok
  end
end

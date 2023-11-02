# frozen_string_literal: true

# UserChannelReceiveJob is executed when the user_channel websocket receives some data
class UserChannelReceiveJob
  include Sidekiq::Worker

  sidekiq_options retry: false # we don't want to retry this job in case of error

  def perform(room_id, data, current_user_id = nil)
    @room_id = room_id
    @data = data
    @current_user_id = current_user_id

    raise(StandardError, "missing '_controller' or '_action' parameters") unless p_controller && p_action

    raise(StandardError, 'unauthorized') unless controller.authorized?(parameters, current_user)

    execute_action
  rescue StandardError => e
    broadcast_error(e) unless settings[:no_broadcast]

    raise e
  end

  private

  def execute_action
    # here we can execute the job synchronously because we are already in a job
    ExecuteActionJob.perform_sync(action.to_s, parameters_sanitized.to_hash, controller.to_s, @room_id, settings)
  end

  def broadcast_error(error)
    ActionCable.server.broadcast(@room_id, { error:, included_in_response: settings[:included_in_response] })
  end

  # when using authentication, update this method to get the user from current_user_id
  # for example: @current_user ||= User.find(current_user_id)
  def current_user
    nil
  end

  def controller
    @controller ||= "Controllers::#{p_controller}::#{p_action}".constantize
  end

  def action
    @action ||= "Actions::#{p_controller}::#{p_action}".constantize
  end

  def parameters
    @parameters ||= @data['params'] || {}
  end

  def parameters_sanitized
    controller.sanitize(ActionController::Parameters.new(parameters), current_user)
  end

  def settings
    @settings ||= {
      # included_in_response is sent back to the client, so it can be used by the client
      # to add information in the response (for example to define the store where to put the result)
      included_in_response: @data['included_in_response'] || {},
      # can be used by the client to cancel any broadcast
      no_broadcast: @data['no_broadcast'],
      # can be used by the client to cancel any broadcast, beside error ones
      broadcast_error_only: @data['broadcast_error_only']
    }
  end

  def p_controller
    @p_controller ||= @data['_controller']&.camelize
  end

  def p_action
    @p_action ||= @data['_action']&.camelize
  end
end

# frozen_string_literal: true

# UserChannelReceiveJob is executed when the user_channel websocket receives some data
class UserChannelReceiveJob
  include Sidekiq::Worker

  sidekiq_options retry: false # we don't want to retry this job in case of error

  # data can be an array of several requests to perform
  def perform(room_id, data, current_user_id = nil)
    @room_id = room_id
    @current_user_id = current_user_id

    # if data contains a "1" key it means that the client sends multiple actions at once
    # so we process them in order, one after the other
    if data['1']
      data.sort.each { |index_request| process_request(index_request[1], request_settings(index_request[1])) }
    else
      process_request(data, request_settings(data))
    end
  end

  private

  def process_request(req, settings)
    raise(StandardError, "missing '_controller' or '_action' parameters") unless req['_controller'] && req['_action']

    controller = constantize_controller(req)

    raise(StandardError, 'unauthorized') unless controller.authorized?(req['params'] || {}, current_user)

    action = constantize_action(req)

    execute_action(controller, action, req, settings)
  rescue StandardError => e
    broadcast_error(e, settings) unless settings[:no_broadcast]

    raise e # we stop the process including the Array loop in case of error
  end

  def execute_action(controller, action, req, settings)
    parameters_sanitized = controller.sanitize(ActionController::Parameters.new(req['params'] || {}), current_user)

    # here we can execute the job synchronously because we are already in a job
    ExecuteActionJob.perform_sync(action.to_s, parameters_sanitized.to_hash, controller.to_s, @room_id, settings)
  end

  def broadcast_error(error, settings)
    ActionCable.server.broadcast(
      @room_id, {
        error: error.message, included_in_response: settings[:included_in_response]
      }
    )
  end

  def request_settings(req)
    {
      # included_in_response is sent back to the client, so it can be used by the client
      # to add information in the response (for example to define the store where to put the result)
      included_in_response: req['included_in_response'] || {},
      # can be used by the client to cancel any broadcast
      no_broadcast: req['no_broadcast'],
      # can be used by the client to cancel any broadcast, beside error ones
      broadcast_error_only: req['broadcast_error_only']
    }
  end

  # when using authentication, update this method to get the user from current_user_id
  # for example: @current_user ||= User.find(current_user_id)
  def current_user
    nil
  end

  def constantize_controller(req)
    "Controllers::#{req['_controller']&.camelize}::#{req['_action']&.camelize}".constantize
  end

  def constantize_action(req)
    "Actions::#{req['_controller']&.camelize}::#{req['_action']&.camelize}".constantize
  end
end

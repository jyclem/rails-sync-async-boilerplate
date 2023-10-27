# frozen_string_literal: true

# UserChannel allows to communicate with a single user
class UserChannel < ApplicationCable::Channel
  def subscribed
    stream_from user_id
  end

  def receive(data)
    @data = data

    raise(StandardError, "missing '_controller' or '_action' parameters") unless p_controller && p_action

    raise(StandardError, 'unauthorized') unless controller.authorized?(parameters, user)

    execute_action
  rescue StandardError => e
    ActionCable.server.broadcast(user_id, { error: e })

    raise e
  end

  private

  def execute_action
    ExecuteActionJob.perform_async(
      action.to_s, controller.sanitize(parameters, user).to_hash,
      controller.to_s, user_id, included_in_response
    )
  end

  def controller
    @controller ||= "Controllers::#{p_controller}::#{p_action}".constantize
  end

  def action
    @action ||= "Actions::#{p_controller}::#{p_action}".constantize
  end

  # used for the client to associate the response to the sender
  # (for example to define the store where to put the result)
  def included_in_response
    @data['included_in_response'] || {}
  end

  def p_controller
    @p_controller ||= @data['_controller']&.camelize
  end

  def p_action
    @p_action ||= @data['_action']&.camelize
  end

  def parameters
    @parameters ||= @data['params']
  end

  def user
    @user ||= defined?(current_user) && current_user
  end
end

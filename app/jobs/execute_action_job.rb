# frozen_string_literal: true

# ExecuteActionJob allows to execute any task asynchronously
class ExecuteActionJob
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # we want to be able to check this job status

  sidekiq_options retry: false # we don't want to retry this job in case of error

  def perform(action, args, controller = nil, room_id = nil, settings = {})
    @action = action
    @args = args
    @controller = controller
    @room_id = room_id
    @settings = settings

    @result = execute_action

    broadcast_result if broadcast_result?
  rescue StandardError => e
    broadcast_error(e) if broadcast_error?

    raise e
  end

  private

  def execute_action
    @action.constantize.new(**@args.symbolize_keys).call || {}
  end

  def broadcast_result
    ActionCable.server.broadcast(
      @room_id, {
        data: @controller.constantize.serialize(@result), included_in_response: @settings['included_in_response']
      }
    )
  end

  def broadcast_error(error)
    ActionCable.server.broadcast(@room_id, { error:, included_in_response: @settings['included_in_response'] })
  end

  def broadcast_result?
    @controller && @room_id && !@settings['broadcast_error_only'] && !@settings['no_broadcast']
  end

  def broadcast_error?
    @controller && @room_id && !@settings['no_broadcast']
  end
end

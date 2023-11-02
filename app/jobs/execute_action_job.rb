# frozen_string_literal: true

# ExecuteActionJob allows to execute any task asynchronously
class ExecuteActionJob
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # we want to be able to check this job status

  sidekiq_options retry: false # we don't want to retry this job in case of error

  def perform(action, args, controller = nil, room_id = nil, settings = {})
    result = action.constantize.new(**args.symbolize_keys).call || {}

    return unless controller && room_id && !settings['broadcast_error_only'] && !settings['no_broadcast']

    ActionCable.server.broadcast(
      room_id, {
        data: controller.constantize.serialize(result), included_in_response: settings['included_in_response']
      }
    )
  end
end

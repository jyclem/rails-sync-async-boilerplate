# frozen_string_literal: true

# ExecuteActionJob allows to execute any task asynchronously
class ExecuteActionJob
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # we want to be able to check this job status

  def perform(action, args, controller = nil, room_id = nil, included_in_response = {})
    result = action.constantize.new(**args.symbolize_keys).call || {}

    return unless controller && room_id

    ActionCable.server.broadcast(
      room_id, { data: controller.constantize.serialize(result), included_in_response: }
    )
  rescue StandardError => e
    ActionCable.server.broadcast(room_id, { error: e }) if controller && room_id

    raise e
  end
end

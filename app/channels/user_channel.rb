# frozen_string_literal: true

# UserChannel allows to communicate with a single user
# Warning: Do not memoize anything called by the "receive" method because
# the channel uses the same instance
class UserChannel < ApplicationCable::Channel
  def subscribed
    stream_from room_id
  end

  def receive(data)
    UserChannelReceiveJob.perform_async(room_id, data, user&.id)
  end

  private

  def user
    defined?(current_user) && current_user
  end
end

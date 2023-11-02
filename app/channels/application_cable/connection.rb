# frozen_string_literal: true

module ApplicationCable
  # Connection
  class Connection < ActionCable::Connection::Base
    identified_by :room_id

    def connect
      # we are not connected (public) so we use a random uuid to identify the user, but in a connected mode
      # we should set the user from an encrypted cookie such as "user_id" or "session_id"
      # https://guides.rubyonrails.org/action_cable_overview.html#connection-setup
      self.room_id = SecureRandom.uuid
    end
  end
end

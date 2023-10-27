# frozen_string_literal: true

module Controllers
  module Todos
    # Classic update
    class Update < Controllers::Base
      def authorized?
        true
      end

      def sanitize
        params.permit(:id, :name)
      end

      def serialize
        result.slice(:id, :name)
      end
    end
  end
end

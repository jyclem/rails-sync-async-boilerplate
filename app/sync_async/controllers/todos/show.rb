# frozen_string_literal: true

module Controllers
  module Todos
    # Classic show
    class Show < Controllers::Base
      def authorized?
        true
      end

      def sanitize
        params.permit(:id)
      end

      def serialize
        result.slice(:id, :name)
      end
    end
  end
end

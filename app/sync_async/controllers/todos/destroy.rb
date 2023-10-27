# frozen_string_literal: true

module Controllers
  module Todos
    # Classic destroy
    class Destroy < Controllers::Base
      def authorized?
        true
      end

      def sanitize
        params.permit(:id)
      end

      def serialize
        result.slice(:id, :name).merge(_destroy: true)
      end
    end
  end
end

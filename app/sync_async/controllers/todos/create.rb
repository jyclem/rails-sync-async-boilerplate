# frozen_string_literal: true

module Controllers
  module Todos
    # Classic create
    class Create < Controllers::Base
      def authorized?
        true
      end

      def sanitize
        params.permit(:name)
      end

      def serialize
        result.slice(:id, :name)
      end
    end
  end
end

# frozen_string_literal: true

module Controllers
  module Todos
    # Classic index
    class Index < Controllers::Base
      def authorized?
        false
      end

      def serialize
        result.map { |todo| todo.slice(:id, :name) }
      end
    end
  end
end

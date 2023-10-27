# frozen_string_literal: true

module Tasks
  module Todos
    # just an example of how to handle a "callback" (we would probably not do this in real life)
    class LogTodos < Tasks::Base
      def initialize(action:, todo_or_todos:) # rubocop:disable Lint/MissingSuper
        @action = action
        @todo_or_todos = todo_or_todos
      end

      def call
        Rails.logger.info "LOGGING: #{@action} for #{Array(@todo_or_todos).map(&:name).join(', ')}"
      end
    end
  end
end

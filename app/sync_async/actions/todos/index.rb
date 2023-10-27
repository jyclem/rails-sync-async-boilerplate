# frozen_string_literal: true

module Actions
  module Todos
    # Index action
    class Index < Actions::Base
      def call
        log_todos

        list_todos # we need to return the todos at the end of the "call" method for serialization
      end

      private

      def list_todos
        @list_todos ||= Todo.all.to_a
      end

      def log_todos
        Tasks::Todos::LogTodos.call(action: 'index', todo_or_todos: list_todos)
      end
    end
  end
end

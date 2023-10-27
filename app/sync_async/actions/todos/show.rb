# frozen_string_literal: true

module Actions
  module Todos
    # Show action
    class Show < Actions::Base
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      def call
        log_todos

        todo # we need to return the todo at the end of the "call" method for serialization
      end

      private

      def log_todos
        Tasks::Todos::LogTodos.call(action: 'show', todo_or_todos: todo)
      end

      def todo
        @todo ||= Todo.find(@id)
      end
    end
  end
end

# frozen_string_literal: true

module Actions
  module Todos
    # Destroy action
    class Destroy < Actions::Base
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      def call
        destroy_todo

        log_todos

        todo # we need to return the todo at the end of the "call" method for serialization
      end

      private

      def destroy_todo
        todo.destroy!
      end

      def log_todos
        Tasks::Todos::LogTodos.call(action: 'destroy', todo_or_todos: todo)
      end

      def todo
        @todo ||= Todo.find(@id)
      end
    end
  end
end

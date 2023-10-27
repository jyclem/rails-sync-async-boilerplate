# frozen_string_literal: true

module Actions
  module Todos
    # Update action
    class Update < Actions::Base
      def initialize(id:, name:) # rubocop:disable Lint/MissingSuper
        @id = id
        @name = name
      end

      def call
        update_todo

        log_todos

        todo # we need to return the todo at the end of the "call" method for serialization
      end

      private

      def update_todo
        todo.update!(name: @name)
      end

      def log_todos
        Tasks::Todos::LogTodos.call(action: 'update', todo_or_todos: todo)
      end

      def todo
        @todo ||= Todo.find(@id)
      end
    end
  end
end

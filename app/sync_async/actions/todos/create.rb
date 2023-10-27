# frozen_string_literal: true

module Actions
  module Todos
    # Create action
    class Create < Actions::Base
      def initialize(name:) # rubocop:disable Lint/MissingSuper
        @name = name
      end

      def call
        log_todos

        todo # we need to return the todo at the end of the "call" method for serialization
      end

      private

      def todo
        @todo ||= Todo.create!(name: @name)
      end

      def log_todos
        Tasks::Todos::LogTodos.call(action: 'create', todo_or_todos: todo)
      end
    end
  end
end

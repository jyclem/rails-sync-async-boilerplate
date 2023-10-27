# frozen_string_literal: true

# Create a Todo table
class CreateTodos < ActiveRecord::Migration[7.1]
  def change
    create_table :todos do |t|
      t.string :name

      t.timestamps
    end
  end
end

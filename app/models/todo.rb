# frozen_string_literal: true

# Todo
class Todo < ApplicationRecord
  validates :name, presence: true
end

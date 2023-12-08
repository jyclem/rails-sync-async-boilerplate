# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actions::Todos::Index do
  subject(:call) { described_class.new.call }

  let!(:todos) { Todo.create!(Array.new(3) { { name: Faker::Lorem.word } }) } # we would normally use a factory here

  before { allow(Tasks::Todos::LogTodos).to receive(:call) }

  it { is_expected.to eql(todos) }

  it 'calls Tasks::Todos::LogTodos.call with the right parameters' do
    call

    expect(Tasks::Todos::LogTodos).to have_received(:call).with(action: 'index', todo_or_todos: todos)
  end
end

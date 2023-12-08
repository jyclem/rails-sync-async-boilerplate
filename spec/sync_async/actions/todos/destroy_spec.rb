# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actions::Todos::Destroy do
  subject(:call) { described_class.new(id: todo_id).call }

  let!(:todo) { Todo.create!(name: Faker::Lorem.word) } # we would normally use a factory here
  let(:todo_id) { todo.id }

  before { allow(Tasks::Todos::LogTodos).to receive(:call) }

  it { is_expected.to eql(todo) }

  it 'destroys the todo' do
    call

    expect(Todo.find_by(id: todo_id)).to be_nil
  end

  it 'calls Tasks::Todos::LogTodos.call with the right parameters' do
    call

    expect(Tasks::Todos::LogTodos).to have_received(:call).with(action: 'destroy', todo_or_todos: todo)
  end

  context 'when the todo is not found' do
    let(:todo_id) { -1 }

    it 'raises an error' do
      expect { call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actions::Todos::Update do # rubocop:disable Metrics/BlockLength
  subject(:call) { described_class.new(id: todo_id, name: new_name).call }

  let!(:todo) { Todo.create!(name: Faker::Lorem.word) } # we would normally use a factory here
  let(:todo_id) { todo.id }
  let(:new_name) { 'new_name' }

  before { allow(Tasks::Todos::LogTodos).to receive(:call) }

  it { is_expected.to eql(todo) }

  it 'updates the todo' do
    call

    expect(todo.reload.name).to eql('new_name')
  end

  it 'calls Tasks::Todos::LogTodos.call with the right parameters' do
    call

    expect(Tasks::Todos::LogTodos).to have_received(:call).with(action: 'update', todo_or_todos: todo)
  end

  context 'when the todo is not found' do
    let(:todo_id) { -1 }

    it 'raises an error' do
      expect { call }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when name is empty' do
    let(:new_name) { nil }

    it 'raises an error' do
      expect { call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

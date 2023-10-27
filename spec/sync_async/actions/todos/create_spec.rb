# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actions::Todos::Create do
  subject(:call) { described_class.new(name:).call }

  let(:name) { Faker::Lorem.word }

  before do
    allow(Tasks::Todos::LogTodos).to receive(:call)
  end

  it 'returns the created todo' do
    todo = Todo.create!(name:) # we would use a factory here
    allow(Todo).to receive(:create!).and_return(todo)

    expect(call).to eql(todo)
  end

  it 'creates a new todo' do
    expect { call }.to change(Todo, :count).by(1)
  end

  it 'calls Tasks::Todos::LogTodos.call with the right parameters' do
    todo = Todo.create!(name:) # we would use a factory here
    allow(Todo).to receive(:create!).and_return(todo)

    call

    expect(Tasks::Todos::LogTodos).to have_received(:call).with(action: 'create', todo_or_todos: todo)
  end

  context 'when name is empty' do
    let(:name) { nil }

    it 'raises an error' do
      expect { call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end

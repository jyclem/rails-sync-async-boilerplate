# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tasks::Todos::LogTodos do
  subject(:log_todos) { described_class.new(action:, todo_or_todos:).call }

  let(:action) { 'any_action' }
  let(:todo_or_todos) { Todo.create!([{ name: 'todo1' }, { name: 'todo2' }]) } # we would use a factory here

  before { allow(Rails.logger).to receive(:info) }

  it 'logs' do
    log_todos

    expect(Rails.logger).to have_received(:info).with('LOGGING: any_action for todo1, todo2')
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExecuteActionJob, type: :job do # rubocop:disable Metrics/BlockLength
  subject(:execute_async_job) do
    ExecuteActionJob.perform_sync(action, args, controller, room_id, included_in_response)
  end

  let(:action) { 'Actions::Base' }
  let(:args) { { 'foo' => 'bar' } }
  let(:controller) { 'Controllers::Base' }
  let(:room_id) { SecureRandom.uuid }
  let(:included_in_response) { { 'baz' => 'qux' } }

  let(:instance_of_actions_base) { double('instance_of_actions_base') }
  let(:result_of_actions_base_call) { double('result_of_actions_base_call') }
  let(:result_of_controllers_base_serialize) { double('result_of_controllers_base_serialize') }

  before do
    allow(Actions::Base).to receive(:new).and_return(instance_of_actions_base)
    allow(instance_of_actions_base).to receive(:call).and_return(result_of_actions_base_call)

    allow(Controllers::Base).to receive(:serialize).and_return(result_of_controllers_base_serialize)

    allow(ActionCable.server).to receive(:broadcast)
  end

  it 'calls the associated action' do
    execute_async_job

    expect(Actions::Base).to have_received(:new).with(foo: 'bar')
    expect(instance_of_actions_base).to have_received(:call)
  end

  it 'broadcasts the result to the correct room' do
    execute_async_job

    expect(Controllers::Base).to have_received(:serialize).with(result_of_actions_base_call)
    expect(ActionCable.server).to have_received(:broadcast).with(
      room_id, { data: result_of_controllers_base_serialize, included_in_response: { 'baz' => 'qux' } }
    )
  end

  context 'when no controller is given in parameter' do
    let(:controller) { nil }

    it 'does not broadcast the result' do
      execute_async_job

      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  context 'when no room_id is given in parameter' do
    let(:room_id) { nil }

    it 'does not broadcast the result' do
      execute_async_job

      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end

  context 'when an error is raised' do
    let(:error_raised) { StandardError.new('error') }

    before { allow(Actions::Base).to receive(:new).and_raise(error_raised) }

    it 'broadcasts an error to the correct room' do
      expect do
        execute_async_job
      end.to raise_error(error_raised)

      expect(ActionCable.server).to have_received(:broadcast).with(room_id, { error: error_raised })
    end
  end

  context 'when an error is raised but there is no controller/room in parameter' do
    let(:controller) { nil }
    let(:room_id) { nil }
    let(:error_raised) { StandardError.new('error') }

    before { allow(Actions::Base).to receive(:new).and_raise(error_raised) }

    it 'does not broadcast an error' do
      expect do
        execute_async_job
      end.to raise_error(error_raised)

      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end
end

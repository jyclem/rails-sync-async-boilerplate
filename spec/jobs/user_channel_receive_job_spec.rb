# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserChannelReceiveJob, type: :job do # rubocop:disable Metrics/BlockLength
  subject(:user_channel_receive_job_perform) { described_class.perform_sync(room_id, data, nil) }

  let(:room_id) { 'room_id' }
  let(:data) do
    {
      '_controller' => _controller, '_action' => _action,
      'params' => params, 'included_in_response' => included_in_response,
      'no_broadcast' => no_broadcast, 'broadcast_error_only' => nil
    }
  end
  let(:_controller) { 'any_controller' }
  let(:_action) { 'any_action' }
  let(:params) { { foo: 'bar' } }
  let(:included_in_response) { { baz: 'qux' } }
  let(:no_broadcast) { nil }

  let(:controller) { double('controller', authorized?: true, sanitize: params, to_s: 'controller') }
  let(:action) { double('action', to_s: 'action') }

  before do
    allow_any_instance_of(described_class).to receive(:controller).and_return(controller)
    allow_any_instance_of(described_class).to receive(:action).and_return(action)
    allow(ExecuteActionJob).to receive(:perform_sync)
    allow(ActionCable.server).to receive(:broadcast)
  end

  it 'calls ExecuteActionJob with the right parameters' do
    user_channel_receive_job_perform

    expect(ExecuteActionJob).to have_received(:perform_sync).with(
      'action', { foo: 'bar' }, 'controller', 'room_id',
      { included_in_response: { 'baz' => 'qux' }, no_broadcast: nil, broadcast_error_only: nil }
    )
  end

  it 'calls controller.authorized? with the right parameters' do
    allow(controller).to receive(:authorized?).and_return(true)

    user_channel_receive_job_perform

    expect(controller).to have_received(:authorized?).with({ 'foo' => 'bar' }, nil)
  end

  it 'calls controller.sanitize with the right parameters' do
    allow(controller).to receive(:sanitize).and_return(params)

    user_channel_receive_job_perform

    expect(controller).to have_received(:sanitize).with(ActionController::Parameters.new({ foo: 'bar' }), nil)
  end

  context 'when _controller is missing in the parameters' do
    let(:_controller) { nil }

    it 'raises an exception' do
      expect { user_channel_receive_job_perform }.to raise_error(
        StandardError, "missing '_controller' or '_action' parameters"
      )
    end
  end

  context 'when _action is missing in the parameters' do
    let(:_action) { nil }

    it 'raises an exception' do
      expect { user_channel_receive_job_perform }.to raise_error(
        StandardError, "missing '_controller' or '_action' parameters"
      )
    end
  end

  context 'when the controller considers that it is not authorized' do
    before { allow(controller).to receive(:authorized?).and_return(false) }

    it 'raises an exception' do
      expect { user_channel_receive_job_perform }.to raise_error(StandardError, 'unauthorized')
    end
  end

  context 'when an error is raised' do
    let(:error_raised) { StandardError.new('error') }

    before { allow(ExecuteActionJob).to receive(:perform_sync).and_raise(error_raised) }

    it 'broadcasts the error on the channel' do
      expect { user_channel_receive_job_perform }.to raise_error(error_raised)

      expect(ActionCable.server).to have_received(:broadcast).with(
        room_id, { error: error_raised, included_in_response: { 'baz' => 'qux' } }
      )
    end
  end

  context 'when an error is raised but no_broadcast is true' do
    let(:error_raised) { StandardError.new('error') }
    let(:no_broadcast) { true }

    before { allow(ExecuteActionJob).to receive(:perform_sync).and_raise(error_raised) }

    it 'does not broadcast the error on the channel' do
      expect { user_channel_receive_job_perform }.to raise_error(error_raised)

      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end
end

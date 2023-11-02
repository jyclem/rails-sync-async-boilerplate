# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe UserChannelReceiveJob, type: :job do
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
    allow_any_instance_of(described_class).to receive(:constantize_controller).and_return(controller)
    allow_any_instance_of(described_class).to receive(:constantize_action).and_return(action)
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

  context 'when data has several requests' do
    let(:data) do
      {
        '1' => { '_controller' => _controller, '_action' => _action, 'params' => params },
        '2' => { '_controller' => _controller, '_action' => _action, 'params' => params }
      }
    end

    it 'calls ExecuteActionJob twice with the right parameters' do
      user_channel_receive_job_perform

      expect(ExecuteActionJob).to have_received(:perform_sync).with(
        'action', { foo: 'bar' }, 'controller', 'room_id',
        { included_in_response: {}, no_broadcast: nil, broadcast_error_only: nil }
      ).twice
    end

    context 'when an error is encountered' do
      let(:data) do
        {
          '1' => { '_controller' => _controller, '_action' => _action, 'params' => params },
          '2' => { '_controller' => nil, '_action' => nil, 'params' => params }, # <= error
          '3' => { '_controller' => _controller, '_action' => _action, 'params' => params }
        }
      end

      it 'does not execute the action after the error occured' do
        expect { user_channel_receive_job_perform }.to raise_error(
          StandardError, "missing '_controller' or '_action' parameters"
        )

        expect(ExecuteActionJob).to have_received(:perform_sync).with(
          'action', { foo: 'bar' }, 'controller', 'room_id',
          { included_in_response: {}, no_broadcast: nil, broadcast_error_only: nil }
        ).once
      end
    end
  end

  context 'when _controller is missing in the parameters' do
    let(:_controller) { nil }

    it 'raises and broadcasts an error' do
      expect { user_channel_receive_job_perform }.to raise_error(
        StandardError, "missing '_controller' or '_action' parameters"
      )

      expect(ActionCable.server).to have_received(:broadcast).with(
        room_id, {
          error: "missing '_controller' or '_action' parameters",
          included_in_response: { 'baz' => 'qux' }
        }
      )
    end
  end

  context 'when _action is missing in the parameters' do
    let(:_action) { nil }

    it 'raises and broadcasts an error' do
      expect { user_channel_receive_job_perform }.to raise_error(
        StandardError, "missing '_controller' or '_action' parameters"
      )

      expect(ActionCable.server).to have_received(:broadcast).with(
        room_id, {
          error: "missing '_controller' or '_action' parameters",
          included_in_response: { 'baz' => 'qux' }
        }
      )
    end
  end

  context 'when the controller considers that it is not authorized' do
    before { allow(controller).to receive(:authorized?).and_return(false) }

    it 'raises and broadcasts an error' do
      expect { user_channel_receive_job_perform }.to raise_error(StandardError, 'unauthorized')

      expect(ActionCable.server).to have_received(:broadcast).with(
        room_id, { error: 'unauthorized', included_in_response: { 'baz' => 'qux' } }
      )
    end
  end

  context 'when an error is raised' do
    let(:error_raised) { StandardError.new('error') }

    before { allow(ExecuteActionJob).to receive(:perform_sync).and_raise(error_raised) }

    it 'raises and broadcasts an error' do
      expect { user_channel_receive_job_perform }.to raise_error(StandardError, 'error')

      expect(ActionCable.server).to have_received(:broadcast).with(
        room_id, { error: 'error', included_in_response: { 'baz' => 'qux' } }
      )
    end
  end

  context 'when an error is raised but no_broadcast is true' do
    let(:error_raised) { StandardError.new('error') }
    let(:no_broadcast) { true }

    before { allow(ExecuteActionJob).to receive(:perform_sync).and_raise(error_raised) }

    it 'raises an error but does not broadcast the error on the channel' do
      expect { user_channel_receive_job_perform }.to raise_error(StandardError, 'error')

      expect(ActionCable.server).not_to have_received(:broadcast)
    end
  end
end
# rubocop:enable Metrics/BlockLength

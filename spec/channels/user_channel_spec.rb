# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe UserChannel, type: :channel do
  let(:user_id) { SecureRandom.uuid }

  before do
    stub_connection(user_id:)
  end

  describe '#subscribed' do
    it 'accepts the subscription' do
      subscribe
      expect(subscription).to be_confirmed
    end

    it 'streams from room user_id' do
      subscribe
      expect(subscription).to have_stream_from(user_id)
    end

    it 'allows broadcasting on this room' do
      expect { ActionCable.server.broadcast(user_id, {}) }.to have_broadcasted_to(user_id)
    end
  end

  describe '#receive' do
    subject(:receive_data) { described_class.new(connection, user_id).receive(data) }

    let(:data) do
      {
        '_controller' => _controller, '_action' => _action,
        'params' => params, 'included_in_response' => included_in_response
      }
    end
    let(:params) { { foo: 'bar' } }
    let(:included_in_response) { { baz: 'qux' } }
    let(:_controller) { 'any_controller' }
    let(:_action) { 'any_action' }

    let(:controller) { double('controller', authorized?: true, sanitize: params, to_s: 'controller') }
    let(:action) { double('action', to_s: 'action') }

    before do
      allow_any_instance_of(described_class).to receive(:controller).and_return(controller)
      allow_any_instance_of(described_class).to receive(:action).and_return(action)
      allow(ExecuteActionJob).to receive(:perform_async)
    end

    it 'calls ExecuteActionJob with the right parameters' do
      receive_data

      expect(ExecuteActionJob).to have_received(:perform_async).with(
        'action', { foo: 'bar' }, 'controller', user_id, { baz: 'qux' }
      )
    end

    it 'calls controller.authorized? with the right parameters' do
      allow(controller).to receive(:authorized?).and_return(true)

      receive_data

      expect(controller).to have_received(:authorized?).with({ foo: 'bar' }, nil)
    end

    it 'calls controller.sanitize with the right parameters' do
      allow(controller).to receive(:sanitize).and_return(params)

      receive_data

      expect(controller).to have_received(:sanitize).with(ActionController::Parameters.new({ foo: 'bar' }), nil)
    end

    context 'when an error is raised' do
      let(:error_raised) { StandardError.new('error') }

      before do
        allow(ActionCable.server).to receive(:broadcast)
        allow(ExecuteActionJob).to receive(:perform_async).and_raise(error_raised)
      end

      it 'broadcasts the error on the channel' do
        expect { receive_data }.to raise_error(error_raised)

        expect(ActionCable.server).to have_received(:broadcast).with(
          user_id, { error: error_raised, included_in_response: { baz: 'qux' } }
        )
      end
    end

    context 'when _controller is missing in the parameters' do
      let(:_controller) { nil }

      it 'raises an exception' do
        expect { receive_data }.to raise_error(StandardError, "missing '_controller' or '_action' parameters")
      end
    end

    context 'when _action is missing in the parameters' do
      let(:_action) { nil }

      it 'raises an exception' do
        expect { receive_data }.to raise_error(StandardError, "missing '_controller' or '_action' parameters")
      end
    end

    context 'when the controller considers that it is not authorized' do
      before { allow(controller).to receive(:authorized?).and_return(false) }

      it 'raises an exception' do
        expect { receive_data }.to raise_error(StandardError, 'unauthorized')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

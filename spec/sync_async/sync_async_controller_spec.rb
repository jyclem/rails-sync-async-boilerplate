# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength, RSpec/MultipleMemoizedHelpers
RSpec.describe SyncAsyncController, type: :request do
  subject(:sync_async) do
    instance.send(:remove_useless_params)
    instance.send(:call)
  end

  let(:instance) { described_class.new }
  let(:params) { { foo: 'bar' } }
  let(:request) { OpenStruct.new(headers: {}) } # rubocop:disable Style/OpenStructUse
  let(:response) { ActionDispatch::Response.new.tap { _1.status = :ok } }
  let(:result) { { baz: 'qux' } }
  let(:controller) { double('controller', authorized?: true, sanitize: { foo: 'bar' }, serialize: result) } # rubocop:disable RSpec/VerifiedDoubles
  let(:action) { double('action', to_s: 'action', call: 'action_result') } # rubocop:disable RSpec/VerifiedDoubles
  let(:job_id) { SecureRandom.hex }

  before do
    allow(instance).to receive_messages(params:)
    allow(instance).to receive_messages(request:)
    instance.instance_variable_set(:@_response, response) # allow(instance).to receive(:response).and_return(response)
    allow(instance).to receive_messages(action_name: :index)
    allow(instance).to receive_messages(controller:)
    allow(instance).to receive_messages(action:)

    allow(ExecuteActionJob).to receive(:perform_async).and_return(job_id)
  end

  shared_examples 'running both synchronously and asynchronously' do
    it 'calls controller.authorized? with the right parameters' do
      allow(controller).to receive(:authorized?).and_return(controller.authorized?)

      sync_async

      expect(controller).to have_received(:authorized?).with({ foo: 'bar' }, nil)
    end

    it 'calls controller.sanitize with the right parameters' do
      allow(controller).to receive(:sanitize).and_return(controller.sanitize)

      sync_async

      expect(controller).to have_received(:sanitize).with({ foo: 'bar' }, nil)
    end

    context 'when the controller considers it is not authorized' do
      let(:controller) { double('controller', authorized?: false, sanitize: { foo: 'bar' }, serialize: result) } # rubocop:disable RSpec/VerifiedDoubles

      before { allow(Rails.logger).to receive(:send) }

      it 'renders a successful response' do
        sync_async

        expect(response).to be_unauthorized
      end

      it 'returns the expected result' do
        sync_async

        expect(JSON.parse(response.body)).to eql('error' => 'HttpUnauthorized')
      end

      it 'logs the error' do
        sync_async

        expect(Rails.logger).to have_received(:send).with(:info, any_args)
      end
    end

    context 'when an exception is raised' do
      let(:error_raised) { StandardError.new('error') }

      before do
        allow(instance).to receive(:action_name).and_raise(error_raised)
        allow(Rails.logger).to receive(:send)
      end

      it 'renders a successful response' do
        sync_async

        expect(response).to have_http_status(:internal_server_error)
      end

      it 'returns the expected result' do
        sync_async

        expect(JSON.parse(response.body)).to eql({ 'error' => 'error' })
      end

      it 'logs the error' do
        sync_async

        expect(Rails.logger).to have_received(:send).with(:error, any_args)
      end
    end
  end

  context 'when running synchronously' do
    it_behaves_like 'running both synchronously and asynchronously'

    it 'renders a successful response' do
      sync_async

      expect(response).to be_successful
    end

    it 'returns the expected result' do
      sync_async

      expect(JSON.parse(response.body)).to eql('baz' => 'qux')
    end

    it 'calls controller.serialize with the right parameters' do
      allow(controller).to receive(:serialize).and_return(controller.serialize)

      sync_async

      expect(controller).to have_received(:serialize).with('action_result')
    end

    it 'does not call ExecuteActionJob.perform_async' do
      sync_async

      expect(ExecuteActionJob).not_to have_received(:perform_async)
    end
  end

  context 'when running asynchronously' do
    let(:request) { OpenStruct.new(headers: { 'async' => 'true' }) } # rubocop:disable Style/OpenStructUse

    it_behaves_like 'running both synchronously and asynchronously'

    it 'renders a successful response' do
      sync_async

      expect(response).to be_successful
    end

    it 'returns the expected result' do
      sync_async

      expect(JSON.parse(response.body)).to eql('job_id' => job_id)
    end

    it 'does not call controller.serialize' do
      allow(controller).to receive(:serialize)

      sync_async

      expect(controller).not_to have_received(:serialize)
    end

    it 'calls ExecuteActionJob.perform_async with the right parameters' do
      sync_async

      expect(ExecuteActionJob).to have_received(:perform_async).with('action', { foo: 'bar' })
    end
  end
end
# rubocop:enable Metrics/BlockLength, RSpec/MultipleMemoizedHelpers

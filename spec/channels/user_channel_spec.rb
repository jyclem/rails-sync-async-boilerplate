# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserChannel do
  let(:room_id) { SecureRandom.uuid }

  before do
    stub_connection(room_id:)
  end

  describe '#subscribed' do
    it 'accepts the subscription' do
      subscribe
      expect(subscription).to be_confirmed
    end

    it 'streams from room room_id' do
      subscribe
      expect(subscription).to have_stream_from(room_id)
    end

    it 'allows broadcasting on this room' do
      expect { ActionCable.server.broadcast(room_id, {}) }.to have_broadcasted_to(room_id)
    end
  end

  describe '#receive' do
    subject(:receive_data) { described_class.new(connection, room_id).receive('any_data') }

    before { allow(UserChannelReceiveJob).to receive(:perform_async) }

    it 'calls UserChannelReceiveJob with the right parameters' do
      receive_data

      expect(UserChannelReceiveJob).to have_received(:perform_async).with(room_id, 'any_data', nil)
    end
  end
end

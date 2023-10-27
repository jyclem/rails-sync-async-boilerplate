# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  it 'successfully connects' do
    connect '/cable'
    expect(connection.user_id).to be_present
  end
end

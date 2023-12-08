# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  it 'successfully connects' do
    connect '/cable'
    expect(connection.room_id).to be_present
  end
end

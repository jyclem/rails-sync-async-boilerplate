# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Controllers::Todos::Update do
  subject(:controller) { described_class.new(params:, result:) }

  let(:params) { ActionController::Parameters.new(id: 'any_id', name: 'new_name', other_param: 'other_param') }
  let(:result) { { id: 'any_id', name: 'new_name' } }

  it 'authorizes?' do
    expect(controller.authorized?).to be true
  end

  it 'sanitizes' do
    expect(controller.sanitize.to_h).to eql('id' => 'any_id', 'name' => 'new_name')
  end

  it 'serializes' do
    expect(controller.serialize).to eql(id: 'any_id', name: 'new_name')
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Controllers::Todos::Show do
  subject(:controller) { described_class.new(params:, result:) }

  let(:params) { ActionController::Parameters.new(id: 'any_id', other_param: 'other_param') }
  let(:result) { { id: 'some_id', name: 'some_name' } }

  it 'authorizes?' do
    expect(controller.authorized?).to be true
  end

  it 'sanitizes' do
    expect(controller.sanitize.to_h).to eql('id' => 'any_id')
  end

  it 'serializes' do
    expect(controller.serialize).to eql(id: 'some_id', name: 'some_name')
  end
end

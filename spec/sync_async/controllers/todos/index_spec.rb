# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Controllers::Todos::Index do
  subject(:controller) { described_class.new(result:) }

  let(:result) { [{ id: 'some_id', name: 'some_name' }, { id: 'another_id', name: 'another_name' }] }

  it 'authorizes?' do
    expect(controller.authorized?).to be true
  end

  it 'serializes' do
    expect(controller.serialize).to eql(
      [{ id: 'some_id', name: 'some_name' }, { id: 'another_id', name: 'another_name' }]
    )
  end
end

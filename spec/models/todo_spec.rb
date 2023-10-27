# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Todo, type: :model do
  describe 'validations' do
    subject { described_class.new(name:) }

    let(:name) { Faker::Lorem.word }

    it { is_expected.to be_valid }

    context 'when there is no name' do
      let(:name) { nil }

      it { is_expected.to be_invalid }
    end
  end
end

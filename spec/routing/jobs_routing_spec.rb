# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobsController, type: :routing do
  describe 'routing' do
    it 'routes to #show' do
      expect(get: '/jobs/1').to route_to('jobs#show', id: '1')
    end
  end
end

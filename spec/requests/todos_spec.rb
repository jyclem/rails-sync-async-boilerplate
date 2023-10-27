# frozen_string_literal: true

require 'rails_helper'

# IMPORTANT:
# Here (and only here), it is suggested to make integration tests, that is to say to check the whole
# process, including the response of the request but also any other results expected by the action
# (such contacting tiers services, sending emails, creating objects, logging, ...).
# Stub/Mock as less as possible here (maybe only for tiers services or logging)
# In all other tests, we should do isolated tests (stubbing/mocking everything)
# Doing so allows to have a good testing coverage while mitigating performances impacts

Dir["#{__dir__}/todos/*.rb"].each { |file| require_relative file }

RSpec.describe '/todos', type: :request do
  let(:valid_attributes) do
    { name: Faker::Lorem.word }
  end

  let(:invalid_attributes) do
    { name: nil }
  end

  let(:valid_headers) do
    {}
  end

  it_behaves_like 'GET /index'
  it_behaves_like 'GET /show'

  it_behaves_like 'POST /create'
  it_behaves_like('POST /create') { let(:valid_headers) { { async: 'true' } } }

  it_behaves_like 'PATCH /update'
  it_behaves_like('PATCH /update') { let(:valid_headers) { { async: 'true' } } }

  it_behaves_like 'DELETE /destroy'
  it_behaves_like('DELETE /destroy') { let(:valid_headers) { { async: 'true' } } }
end

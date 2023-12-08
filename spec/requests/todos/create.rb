# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
shared_examples 'POST /create' do
  context 'with valid parameters' do
    subject(:post_create) { post(todos_url, params: valid_attributes, headers:, as: :json) }

    let(:expected_result) do
      headers[:async] == 'true' ? { 'job_id' => anything } : { 'id' => anything, 'name' => valid_attributes[:name] }
    end

    it 'returns the correct values' do
      post_create

      expect(response.parsed_body).to match(expected_result)
    end

    it 'creates a new Todo' do
      expect { post_create }.to change(Todo, :count).by(1)
    end

    it 'renders a JSON response with the new todo' do # rubocop:disable RSpec/MultipleExpectations
      post_create

      expect(response).to have_http_status(:created)
      expect(response.content_type).to match(a_string_including('application/json'))
    end

    it 'logs the result' do
      allow(Rails.logger).to receive(:info)

      post_create

      expect(Rails.logger).to have_received(:info).with("LOGGING: create for #{valid_attributes[:name]}")
    end
  end

  context 'with invalid parameters' do
    subject(:post_create) { post todos_url, params: invalid_attributes, headers:, as: :json }

    it 'returns the correct values' do
      post_create

      expect(response.parsed_body).to eql('error' => "Validation failed: Name can't be blank")
    end

    it 'does not create a new Todo' do
      expect { post_create }.not_to change(Todo, :count)
    end

    it 'renders a JSON response with errors for the new todo' do # rubocop:disable RSpec/MultipleExpectations
      post_create

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.content_type).to match(a_string_including('application/json'))
    end

    it 'logs the error' do
      allow(Rails.logger).to receive(:info)

      post_create

      expect(Rails.logger).to have_received(:info).with(a_string_matching(/Validation failed: Name can't be blank/))
    end
  end
end
# rubocop:enable Metrics/BlockLength

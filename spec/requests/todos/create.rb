# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
shared_examples 'POST /create' do
  describe do
    context 'with valid parameters' do
      subject(:post_create) { post(todos_url, params: valid_attributes, headers: valid_headers, as: :json) }

      it 'returns the correct values' do
        post_create

        if valid_headers[:async] == 'true'
          expect(JSON.parse(response.body)).to match('job_id' => anything)
        else
          expect(JSON.parse(response.body)).to match('id' => anything, 'name' => valid_attributes[:name])
        end
      end

      it 'creates a new Todo' do
        expect { post_create }.to change(Todo, :count).by(1)
      end

      it 'renders a JSON response with the new todo' do
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
      subject(:post_create) { post todos_url, params: invalid_attributes, headers: valid_headers, as: :json }

      it 'returns the correct values' do
        post_create

        expect(JSON.parse(response.body)).to eql('error' => "Validation failed: Name can't be blank")
      end

      it 'does not create a new Todo' do
        expect { post_create }.to change(Todo, :count).by(0)
      end

      it 'renders a JSON response with errors for the new todo' do
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
end
# rubocop:enable Metrics/BlockLength

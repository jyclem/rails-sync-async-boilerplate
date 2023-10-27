# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
shared_examples 'PATCH /update' do
  describe do
    context 'with valid parameters' do
      subject(:patch_update) { patch(todo_url(todo), params: new_attributes, headers: valid_headers, as: :json) }

      let!(:todo) { Todo.create!(valid_attributes) }

      let(:new_attributes) do
        { name: 'new_name' }
      end

      it 'returns the correct values' do
        patch_update

        if valid_headers[:async] == 'true'
          expect(JSON.parse(response.body)).to match('job_id' => anything)
        else
          expect(JSON.parse(response.body)).to match('id' => todo.id, 'name' => 'new_name')
        end
      end

      it 'updates the requested todo' do
        patch_update
        todo.reload

        expect(todo.name).to eql 'new_name'
      end

      it 'renders a JSON response with the todo' do
        patch_update

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including('application/json'))
      end

      it 'logs the result' do
        allow(Rails.logger).to receive(:info)

        patch_update

        expect(Rails.logger).to have_received(:info).with('LOGGING: update for new_name')
      end
    end

    context 'with invalid parameters' do
      subject(:patch_update) { patch(todo_url(todo), params: invalid_attributes, headers: valid_headers, as: :json) }

      let!(:todo) { Todo.create!(valid_attributes) }

      it 'returns the correct values' do
        patch_update

        expect(JSON.parse(response.body)).to eql('error' => "Validation failed: Name can't be blank")
      end

      it 'does not update a new Todo' do
        expect { patch_update }.not_to change(todo, :name)
      end

      it 'renders a JSON response with errors for the todo' do
        patch_update

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including('application/json'))
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:info)

        patch_update

        expect(Rails.logger).to have_received(:info).with(a_string_matching(/Validation failed: Name can't be blank/))
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

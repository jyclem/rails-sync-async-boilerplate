# frozen_string_literal: true

shared_examples 'DELETE /destroy' do
  describe do
    subject(:delete_destroy) { delete todo_url(todo), headers: valid_headers, as: :json }

    let!(:todo) { Todo.create!(valid_attributes) }

    it 'returns the correct values' do
      delete_destroy

      if valid_headers[:async] == 'true'
        expect(JSON.parse(response.body)).to match('job_id' => anything)
      else
        expect(JSON.parse(response.body)).to match('id' => anything, 'name' => todo.name, '_destroy' => true)
      end
    end

    it 'destroys the requested todo' do
      expect { delete_destroy }.to change(Todo, :count).by(-1)
    end

    it 'renders a JSON response with the new todo' do
      delete_destroy

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(a_string_including('application/json'))
    end

    it 'logs the result' do
      allow(Rails.logger).to receive(:info)

      delete_destroy

      expect(Rails.logger).to have_received(:info).with("LOGGING: destroy for #{todo.name}")
    end
  end
end

# frozen_string_literal: true

shared_examples 'GET /index' do
  describe do
    subject(:get_index) { get(todos_url, headers: valid_headers, as: :json) }

    let!(:todo) { Todo.create! valid_attributes }

    it 'renders a successful response' do
      get_index

      expect(response).to be_successful
    end

    it 'returns the correct values' do
      get_index

      expect(JSON.parse(response.body)).to eql([{ 'id' => todo.id, 'name' => todo.name }])
    end

    it 'logs the result' do
      allow(Rails.logger).to receive(:info)

      get_index

      expect(Rails.logger).to have_received(:info).with("LOGGING: index for #{valid_attributes[:name]}")
    end
  end
end

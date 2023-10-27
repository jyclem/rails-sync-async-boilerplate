# frozen_string_literal: true

shared_examples 'GET /show' do
  describe do
    subject(:get_show) { get(todo_url(todo), as: :json) }

    let!(:todo) { Todo.create!(valid_attributes) }

    it 'renders a successful response' do
      get_show

      expect(response).to be_successful
    end

    it 'returns the correct values' do
      get_show

      expect(JSON.parse(response.body)).to eql('id' => todo.id, 'name' => todo.name)
    end

    it 'logs the result' do
      allow(Rails.logger).to receive(:info)

      get_show

      expect(Rails.logger).to have_received(:info).with("LOGGING: show for #{todo.name}")
    end
  end
end

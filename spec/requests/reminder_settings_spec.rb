require 'rails_helper'

RSpec.describe "ReminderSettings", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'GET /reminder_settings は 200' do
    get reminder_settings_path
    expect(response).to have_http_status(:ok)
  end
end

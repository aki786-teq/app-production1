require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before do
    sign_in user
  end

  it 'GET /notifications は 200 を返す' do
    get notifications_path
    expect(response).to have_http_status(:ok)
  end

  it 'DELETE /notifications/destroy_all は リダイレクトする' do
    delete destroy_all_notifications_path
    expect([302, 303]).to include(response.status)
    expect(response).to redirect_to(notifications_path)
  end
end



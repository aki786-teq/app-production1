require 'rails_helper'

RSpec.describe "ReminderSettings", type: :request do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  before { sign_in user }

  it 'GET /reminder_settings は 200' do
    get reminder_settings_path
    expect(response).to have_http_status(:ok)
  end

  it 'PATCH /reminder_settings 更新成功でリダイレクト' do
    patch reminder_settings_path, params: { line_notification: { notification_enabled: false } }
    expect([ 302, 303 ]).to include(response.status)
    expect(response).to redirect_to(reminder_settings_path)
  end

  it 'PATCH /reminder_settings バリデーションエラーで422' do
    # booleanに nil を送るため、パラメータをあえて欠落させる
    patch reminder_settings_path, params: { line_notification: { notification_enabled: nil } }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end

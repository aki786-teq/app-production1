require 'rails_helper'

RSpec.describe "LineWebhook errors", type: :request do
  let(:path) { "/line/webhook" }

  it '予期しない例外でも 500 を返す（callback直下で例外）' do
    # シグネチャ検証メソッドで例外を起こさせ、callback の rescue => 500 を通す
    allow_any_instance_of(LineWebhookController).to receive(:valid_signature?).and_raise(StandardError, 'boom')

    body = { events: [] }.to_json
    headers = { 'CONTENT_TYPE' => 'application/json', 'HTTP_X_LINE_SIGNATURE' => 'anything' }
    post path, params: body, headers: headers

    expect(response).to have_http_status(:internal_server_error)
  end
end



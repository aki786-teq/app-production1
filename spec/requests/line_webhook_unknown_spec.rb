require 'rails_helper'

RSpec.describe "LineWebhook unknown event", type: :request do
  let(:path) { "/line/webhook" }

  def sign_header(body, secret)
    signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, body))
    { 'HTTP_X_LINE_SIGNATURE' => signature }
  end

  it '未知の event.type でも 200' do
    body = { events: [ { 'type' => 'unknown', 'replyToken' => 'x', 'source' => { 'userId' => 'U1' } } ] }.to_json
    headers = sign_header(body, 'secret').merge('CONTENT_TYPE' => 'application/json')

    old_secret = ENV['LINE_CHANNEL_SECRET']
    begin
      ENV['LINE_CHANNEL_SECRET'] = 'secret'
      post path, params: body, headers: headers
    ensure
      ENV['LINE_CHANNEL_SECRET'] = old_secret
    end

    expect(response).to have_http_status(:ok)
  end
end

require 'rails_helper'

RSpec.describe "LineWebhook message", type: :request do
  let(:path) { "/line/webhook" }

  def sign_header(body, secret)
    signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, body))
    { 'HTTP_X_LINE_SIGNATURE' => signature }
  end

  before do
    allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(double(
      reply_message_with_http_info: [nil, 200, {}],
      push_message_with_http_info: [nil, 200, {}]
    ))
  end

  it 'message の link キーワードでリンクを返信し 200' do
    body = {
      events: [
        {
          'type' => 'message',
          'replyToken' => 'dummy',
          'source' => { 'userId' => 'Uxxxx' },
          'message' => { 'type' => 'text', 'text' => 'link ください' }
        }
      ]
    }.to_json

    headers = sign_header(body, 'secret').merge('CONTENT_TYPE' => 'application/json')
    old_secret = ENV['LINE_CHANNEL_SECRET']
    old_token = ENV['LINE_CHANNEL_TOKEN']
    begin
      ENV['LINE_CHANNEL_SECRET'] = 'secret'
      ENV['LINE_CHANNEL_TOKEN'] = 'token'
      post path, params: body, headers: headers
    ensure
      ENV['LINE_CHANNEL_SECRET'] = old_secret
      ENV['LINE_CHANNEL_TOKEN'] = old_token
    end

    expect(response).to have_http_status(:ok)
  end
end



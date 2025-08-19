require 'rails_helper'

RSpec.describe "LineWebhook reply fallback", type: :request do
  let(:path) { "/line/webhook" }

  def sign_header(body, secret)
    signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, body))
    { 'HTTP_X_LINE_SIGNATURE' => signature }
  end

  it 'replyが非200のときpushでフォールバックしても 200 を返す（pushは呼ばれる）' do
    # replyは500で失敗、pushは200で成功
    client = double(
      reply_message_with_http_info: [ nil, 500, {} ],
      push_message_with_http_info: [ nil, 200, {} ]
    )
    expect(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(client)

    body = {
      events: [
        { 'type' => 'follow', 'replyToken' => 'dummy', 'source' => { 'userId' => 'Uxxxx' } }
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

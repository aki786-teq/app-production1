require 'rails_helper'

RSpec.describe "LineWebhook", type: :request do
  let(:path) { "/line/webhook" }

  def sign_header(body, secret)
    signature = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, body))
    { 'HTTP_X_LINE_SIGNATURE' => signature }
  end

  it '署名不正なら 400' do
    body = { events: [] }.to_json
    old_secret = ENV['LINE_CHANNEL_SECRET']
    begin
      ENV['LINE_CHANNEL_SECRET'] = 'secret'
      post path, params: body, headers: { 'CONTENT_TYPE' => 'application/json', 'HTTP_X_LINE_SIGNATURE' => 'bad' }
      expect(response).to have_http_status(:bad_request)
    ensure
      ENV['LINE_CHANNEL_SECRET'] = old_secret
    end
  end

  it '有効署名で follow イベントを処理して 200' do
    body = {
      events: [
        {
          'type' => 'follow',
          'replyToken' => 'dummy',
          'source' => { 'userId' => 'Uxxxx' }
        }
      ]
    }.to_json

    # 署名生成
    headers = sign_header(body, 'secret').merge('CONTENT_TYPE' => 'application/json')

    # 外部API呼び出しをスタブ
    allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(double(
      reply_message_with_http_info: [ nil, 200, {} ],
      push_message_with_http_info: [ nil, 200, {} ]
    ))

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

  it 'JSONパースエラーで 400' do
    post path, params: 'invalid json', headers: { 'CONTENT_TYPE' => 'application/json' }
    expect([ 400, 422 ]).to include(response.status)
  end
end

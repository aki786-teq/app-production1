require 'rails_helper'

RSpec.describe LineInactiveNotifyJob, type: :job do
  let(:user) { create(:user) }
  let(:line_notification) { create(:line_notification, user: user) }
  let(:oauth_account) { create(:oauth_account, user: user, provider: 'line_messaging', uid: 'test_line_id') }
  let(:mock_client) { double('Line::Bot::V2::MessagingApi::ApiClient') }

  before do
    # LINE APIクライアントをモック
    allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:push_message_with_http_info).and_return([ nil, 200, {} ])

    # 環境変数を設定
    allow(ENV).to receive(:fetch).with("LINE_CHANNEL_TOKEN").and_return("test_token")
  end

  describe '#perform' do
    context '正常なケース' do
      before do
        oauth_account
        line_notification
      end

      it 'LINE通知を送信し、通知記録を更新する' do
        expect(mock_client).to receive(:push_message_with_http_info).with(
          hash_including(
            push_message_request: instance_of(Line::Bot::V2::MessagingApi::PushMessageRequest)
          )
        ).and_return([ nil, 200, {} ])

        expect { perform_enqueued_jobs { described_class.perform_later(user.id) } }.
          to change { line_notification.reload.last_notified_at }.from(nil)
      end
    end

    context 'LINE連携されていない場合' do
      it 'エラーログを出力して処理を終了する' do
        expect(Rails.logger).to receive(:error).with("ユーザーID: #{user.id} - LINE連携されていません")

        perform_enqueued_jobs { described_class.perform_later(user.id) }
      end
    end

    context 'ユーザーが存在しない場合' do
      it 'RecordNotFoundエラーをキャッチしてログを出力する' do
        expect(Rails.logger).to receive(:error).with("ユーザーID: 999999 が見つかりません")

        perform_enqueued_jobs { described_class.perform_later(999999) }
      end
    end

    context 'LINE API呼び出しが失敗する場合' do
      before do
        oauth_account
        line_notification
        allow(mock_client).to receive(:push_message_with_http_info).and_return([ nil, 500, {} ])
      end

      it 'エラーを発生させる' do
        expect {
          perform_enqueued_jobs { described_class.perform_later(user.id) }
        }.to raise_error(/LINE通知の送信に失敗しました/)
      end
    end
  end

  describe 'メッセージ内容' do
    before do
      oauth_account
      line_notification
    end

    it 'ユーザー名を含むメッセージを送信する' do
      expect(mock_client).to receive(:push_message_with_http_info) do |args|
        push_request = args[:push_message_request]
        expect(push_request.to).to eq('test_line_id')
        expect(push_request.messages.first.text).to include(user.name)
        expect(push_request.messages.first.text).to include("最後の投稿から3日以上が経過しています")
        [ nil, 200, {} ]
      end

      perform_enqueued_jobs { described_class.perform_later(user.id) }
    end
  end
end

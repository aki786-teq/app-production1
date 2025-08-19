require 'rails_helper'

RSpec.describe Board, type: :model do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }

  describe '画像バリデーション（スタブでC1）' do
    it 'image_type: 未対応コンテントタイプならエラーを追加' do
      board = build(:board, user: user, goal: goal)
      allow(board).to receive_message_chain(:image, :attached?).and_return(true)
      allow(board).to receive_message_chain(:image, :content_type).and_return('image/gif')
      # サイズ検証で落ちないよう、byte_size もスタブ
      allow(board).to receive_message_chain(:image, :blob, :byte_size).and_return(100.kilobytes)
      board.valid?
      expect(board.errors[:image]).to include("はJPEG, PNG, WebP形式の画像のみ対応しています")
    end

    it 'image_size: 1MB超ならエラーを追加' do
      board = build(:board, user: user, goal: goal)
      allow(board).to receive_message_chain(:image, :attached?).and_return(true)
      allow(board).to receive_message_chain(:image, :blob, :byte_size).and_return(2.megabytes)
      allow(board).to receive_message_chain(:image, :content_type).and_return('image/jpeg')
      board.valid?
      expect(board.errors[:image]).to include("は1MB以下の画像を選んでください")
    end

    it 'display_image: 画像未添付なら nil を返す' do
      board = build(:board, user: user, goal: goal)
      fake_attachment = instance_double('ActiveStorage::Attached::One', attached?: false)
      allow(board).to receive(:image).and_return(fake_attachment)
      expect(board.display_image).to be_nil
    end

    it 'display_image: 画像添付なら variant(processed) の結果を返す' do
      board = build(:board, user: user, goal: goal)
      allow(board).to receive_message_chain(:image, :attached?).and_return(true)
      variant_double = double(processed: :processed_ok)
      allow(board).to receive_message_chain(:image, :variant).and_return(variant_double)
      expect(board.display_image).to eq :processed_ok
    end
  end
end

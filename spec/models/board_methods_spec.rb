require 'rails_helper'

RSpec.describe Board, type: :model do
  let(:user) { create(:user) }
  let!(:goal) { create(:goal, user: user) }
  let(:board) { create(:board, user: user, goal: goal, youtube_link: youtube_link) }
  let(:youtube_link) { nil }

  describe '#cheered_by?' do
    it 'ユーザーが応援済みなら true、でなければ false' do
      other = create(:user)
      expect(board.cheered_by?(other)).to be false
      board.cheers.create!(user: other)
      expect(board.cheered_by?(other)).to be true
    end
  end

  describe '#bookmarked_by?' do
    it 'ユーザーがブクマ済みなら true、でなければ false' do
      other = create(:user)
      expect(board.bookmarked_by?(other)).to be false
      board.bookmarks.create!(user: other)
      expect(board.bookmarked_by?(other)).to be true
    end
  end

  describe '#youtube_video_id / #has_youtube_video?' do
    context 'リンクが空' do
      it { expect(board.youtube_video_id).to be_nil }
      it { expect(board.has_youtube_video?).to be false }
    end

    context '有効なリンク' do
      let(:youtube_link) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
      it { expect(board.youtube_video_id).to eq 'dQw4w9WgXcQ' }
      it { expect(board.has_youtube_video?).to be true }
    end

    context '短縮URL (youtu.be)' do
      let(:youtube_link) { 'https://youtu.be/dQw4w9WgXcQ' }
      it { expect(board.youtube_video_id).to eq 'dQw4w9WgXcQ' }
      it { expect(board.has_youtube_video?).to be true }
    end

    context 'クエリ付き URL' do
      let(:youtube_link) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=43s' }
      it { expect(board.youtube_video_id).to eq 'dQw4w9WgXcQ' }
      it { expect(board.has_youtube_video?).to be true }
    end

    context '無効なリンク' do
      let(:youtube_link) { 'https://example.com/video' }
      it 'バリデーションエラーになる' do
        invalid = build(:board, user: user, goal: goal, youtube_link: youtube_link)
        expect(invalid).to be_invalid
        expect(invalid.errors[:youtube_link]).to be_present
      end
    end

    context 'パターンにマッチしない文字列（空でないが不一致）' do
      let(:youtube_link) { 'not a url' }
      let(:board) { build(:board, user: user, goal: goal, youtube_link: youtube_link) }
      it { expect(board.youtube_video_id).to be_nil }
      it { expect(board.has_youtube_video?).to be false }
    end
  end

  describe '#has_stretch_measurement?' do
    it '関連があると true、ないと false' do
      expect(board.has_stretch_measurement?).to be false
      board.stretch_distances << create(:stretch_distance, user: user)
      expect(board.has_stretch_measurement?).to be true
    end
  end
end



class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  validates :name, presence: true
  validates :introduce, length: {
    maximum: 500,
    message: "は500文字以内で入力してください"
  }

  has_one :goal, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_boards, through: :bookmarks, source: :board
  has_many :notifications, dependent: :destroy
  has_many :stretch_distances, dependent: :destroy

  def bookmark(board)
    bookmarked_boards << board
  end

  def unbookmark(board)
    bookmarked_boards.destroy(board)
  end

  def bookmark?(board)
    bookmarked_boards.include?(board)
  end

  # 昨日から4日間継続投稿しているかの判定
  def four_days_consecutive_posts?
    return false if boards.empty?

    # 昨日から4日前までの日付を生成
    start_date = 4.days.ago.to_date
    end_date = 1.day.ago.to_date
    required_dates = (start_date..end_date).to_a

    # 各日に投稿があるかチェック
    posted_dates = boards
      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .pluck(:created_at)
      .map(&:to_date)
      .uniq

    # 4日間すべての日に投稿があるかチェック
    required_dates.all? { |date| posted_dates.include?(date) }
  end

  # 前屈測定機能を利用可能かの判定
  def can_use_stretch_measurement?
    four_days_consecutive_posts?
  end

  # 連続投稿日数を返すメソッド
  def consecutive_post_days
    return 0 if boards.empty?

    today = Time.zone.today
    days = 0

    # 昨日から過去に遡って、投稿がある日を連続してカウント
    (1..4).each do |i|
      day = today - i
      if boards.where(created_at: day.beginning_of_day..day.end_of_day).exists?
        days += 1
      else
        break
      end
    end

    days
  end
end

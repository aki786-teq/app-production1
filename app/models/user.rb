class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  validates :name, presence: true
  validates :introduce, length: {
    maximum: 500,
    message: "は500文字以内で入力してください"
  }
  validates :email, uniqueness: true

  has_one :goal, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_boards, through: :bookmarks, source: :board
  has_many :notifications, dependent: :destroy
  has_many :stretch_distances, dependent: :destroy
  has_one :line_notification, dependent: :destroy
  has_many :line_link_tokens, dependent: :destroy
  has_many :oauth_accounts, dependent: :destroy

  def bookmark(board)
    bookmarked_boards << board
  end

  def unbookmark(board)
    bookmarked_boards.destroy(board)
  end

  def bookmark?(board)
    bookmarked_boards.include?(board)
  end

  # 前屈測定機能を利用可能かの判定
  def can_use_stretch_measurement?
    consecutive_post_days >= 4
  end

  # 連続投稿日数を返すメソッド
  def consecutive_post_days
    return 0 if boards.empty?

    today = Time.zone.today
    (1..4).take_while do |i|
      day = today - i
      boards.where(created_at: day.beginning_of_day..day.end_of_day).exists?
    end.size
  end

  # アプリログイン時、既存ユーザーの検索または新規ユーザーの作成を行う（Google専用）
  def self.from_omniauth(auth)
    user = find_user_by_google(auth) || create_user_for_google!(auth)
    attach_google_oauth!(user, auth)
    user
  end

  # ===== Google OAuth共通処理ここから =====

  def self.find_user_by_google(auth)
    account = OauthAccount.find_by(provider: "google_oauth2", uid: auth.uid)
    return account.user if account

    return find_by(email: auth.info.email) if auth.respond_to?(:info) && auth.info&.email.present?

    nil
  end

  def self.create_user_for_google!(auth)
    email = auth.info.email
    name = extract_name_from_auth(auth)

    user = new(
      email: email,
      name: name,
      password: Devise.friendly_token[0, 20]
    )

    user.skip_confirmation!
    user.save!
    user
  end

  def self.attach_google_oauth!(user, auth)
    return user if user.oauth_accounts.find_by(provider: "google_oauth2")

    user.oauth_accounts.create!(
      provider: "google_oauth2",
      uid: auth.uid,
      auth_data: auth.to_hash
    )

    user
  end

  # 認証情報から名前を抽出
  def self.extract_name_from_auth(auth)
    case auth.provider
    when "google_oauth2"
      auth.info.name || "Google User"
    else
      auth.info.name || "User"
    end
  end

  # ===== Google OAuth共通処理ここまで =====

  # line_notificationsテーブルのレコードを取得または作成
  def line_notification_setting
    line_notification || create_line_notification
  end

  # oauth_accountsのprovider: "line_messaging"のuidが存在するか
  def line_notifiable?
    line_id.present?
  end

  # LINE Messaging APIのuserIdを取得
  def line_id
    oauth_accounts.where(provider: "line_messaging").pick(:uid)
  end
end

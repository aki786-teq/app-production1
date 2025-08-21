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

  # 昨日から4日間継続投稿しているかの判定
  def four_days_consecutive_posts?
    return false if boards.empty?

    start_date = 4.days.ago.to_date
    end_date = 1.day.ago.to_date
    required_dates = (start_date..end_date).to_a

    posted_dates = boards
      .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .pluck(:created_at)
      .map(&:to_date)
      .uniq

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

  # アプリログイン時、既存ユーザーの検索または新規ユーザーの作成を行う（Google専用）
  def self.from_omniauth(auth)
    user = find_user_by_google(auth) || create_user_for_google!(auth)
    attach_google_oauth!(user, auth)
    user
  end

  # ===== Google OAuth共通処理 =====

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

  # LINE通知設定を取得または作成
  def line_notification_setting
    line_notification || create_line_notification
  end

  # LINE通知可能かチェック
  def line_notifiable?
    line_connected?
  end

  # LINEアカウントと連携しているかチェック
  def line_connected?
    line_id.present?
  end

  # Googleアカウントと連携しているかチェック
  def google_connected?
    oauth_accounts.exists?(provider: "google_oauth2")
  end

  # SNSログインユーザーかどうか
  def omniauth_user?
    oauth_accounts.exists?
  end

  # 指定したプロバイダーと連携しているかチェック
  def connected_to?(provider_name)
    oauth_accounts.exists?(provider: provider_name.to_s)
  end

  # 指定したプロバイダーのOAuthAccountを取得
  def oauth_account_for(provider_name)
    oauth_accounts.find_by(provider: provider_name.to_s)
  end

  # LINE Messaging API の userId を取得
  def line_id
    messaging = oauth_account_for("line_messaging")
    messaging&.uid
  end

  protected

  # Deviseのバリデーションをオーバーライド（SNSログイン時のパスワード要求を回避）
  def password_required?
    return false if omniauth_user? && encrypted_password.blank?
    super
  end

  def email_required?
    true
  end
end

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: [:google_oauth2, :line]

  validates :name, presence: true
  validates :introduce, length: {
    maximum: 500,
    message: "は500文字以内で入力してください"
  }
  validates :uid, uniqueness: { scope: :provider }, allow_nil: true
  validates :email, uniqueness: true

  has_one :goal, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :cheers, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_boards, through: :bookmarks, source: :board
  has_many :notifications, dependent: :destroy
  has_many :stretch_distances, dependent: :destroy
  has_one :line_notification, dependent: :destroy

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

  def self.from_omniauth(auth)
    # まず、provider/uidの組み合わせで既存ユーザーをチェック
    user = where(provider: auth.provider, uid: auth.uid).first
    return user if user.present?

    # 同じメールアドレスを持つ既存ユーザーがいるかチェック
    user = find_by(email: auth.info.email) if auth.info.email.present?

    if user
      # 既存ユーザーにSNS情報を紐づけて更新
      user.update!(
        provider: auth.provider,
        uid: auth.uid,
        # LINEの場合はline_idも更新
        line_id: auth.provider == 'line' ? auth.uid : user.line_id
      )
    else
      # 新規ユーザー作成
      email = auth.info.email.present? ? auth.info.email : generate_fake_email(auth.uid, auth.provider)
      name = extract_name_from_auth(auth)

      user = new(
        provider: auth.provider,
        uid: auth.uid,
        email: email,
        name: name,
        password: Devise.friendly_token[0, 20],
        # LINEの場合はline_idも設定
        line_id: auth.provider == 'line' ? auth.uid : nil
      )

      # 確認メールをスキップ（SNSログインの場合）
      user.skip_confirmation!
      user.save!
    end

    user
  end

  # ダミーメール生成（プライベートメソッドとして移動）
  def self.generate_fake_email(uid, provider)
    "#{uid}-#{provider}@example.com"
  end

  # 認証情報から名前を抽出
  def self.extract_name_from_auth(auth)
    case auth.provider
    when 'line'
      auth.info.name || auth.info.display_name || "LINE User"
    when 'google_oauth2'
      auth.info.name || "Google User"
    else
      auth.info.name || "User"
    end
  end

  def self.create_unique_string
    SecureRandom.uuid
  end

  # LINE通知設定を取得または作成
  def line_notification_setting
    line_notification || create_line_notification
  end

  # 最後の投稿日を取得
  def last_post_date
    boards.where(is_deleted: false).maximum(:created_at)&.to_date
  end

  # 指定日数以上投稿していないかチェック
  def inactive_for_days?(days)
    return true if last_post_date.nil?
    last_post_date < days.days.ago.to_date
  end

  # LINE通知可能かチェック
  def line_notifiable?
    line_id.present? && line_notification_setting.notification_enabled?
  end

  # LINEアカウントと連携しているかチェック
  def line_connected?
    provider == 'line' && uid.present? && line_id.present?
  end

  # SNSログインユーザーかどうか
  def omniauth_user?
    provider.present? && uid.present?
  end

  # 通常のパスワードログインが可能かどうか
  def password_required?
    # SNSログインのみのユーザーの場合はパスワード不要
    !omniauth_user? || encrypted_password.present?
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
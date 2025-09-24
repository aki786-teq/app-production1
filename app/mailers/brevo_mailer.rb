require 'brevo'

class BrevoMailer < Devise::Mailer
  default from: ENV['MAILER_SENDER']

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @host = Rails.application.routes.default_url_options[:host]

    confirmation_url = Rails.application.routes.url_helpers.user_confirmation_url(
      confirmation_token: @token,
      host: @host
    )

    # Brevo API の設定
    Brevo.configure do |config|
      config.api_key['api-key'] = ENV['BREVO_API_KEY']
      # partner-key は不要ならコメントアウト
      # config.api_key['partner-key'] = ENV['BREVO_PARTNER_KEY']
    end

    api_instance = Brevo::TransactionalEmailsApi.new

    # メール内容
    html_content = <<~HTML
      <p>こんにちは #{@resource.email} さん、</p>
      <p>以下のリンクをクリックして、メールアドレスの本人確認を完了してください。あなたが希望していない場合、このメールは無視してください。</p>
      <p><a href="#{confirmation_url}">メールアドレス確認を完了する</a></p>
    HTML

    send_smtp_email = Brevo::SendSmtpEmail.new(
      sender: { email: ENV['MAILER_SENDER'], name: "まいにち前屈" },
      to: [{ email: @resource.email }],
      subject: "メールアドレスの確認",
      html_content: html_content
    )

    begin
      api_instance.send_transac_email(send_smtp_email)
    rescue Brevo::ApiError => e
      Rails.logger.error "Brevo email failed: #{e}"
    end
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @host = Rails.application.routes.default_url_options[:host]

    reset_url = Rails.application.routes.url_helpers.edit_user_password_url(
      reset_password_token: @token,
      host: @host
    )

    # Brevo API の設定
    Brevo.configure do |config|
      config.api_key['api-key'] = ENV['BREVO_API_KEY']
    end

    api_instance = Brevo::TransactionalEmailsApi.new

    html_content = <<~HTML
      <p>こんにちは #{@resource.email} さん、</p>
      <p>誰かがパスワードの再設定を希望しました。次のリンクでパスワードの再設定ができます。</p>
      <p><a href="#{reset_url}">パスワード変更</a></p>
      <p>あなたが希望していない場合、このメールは無視してください。</p>
      <p>上のリンクにアクセスして新しいパスワードを設定するまで、パスワードは変更されません。</p>
    HTML

    send_smtp_email = Brevo::SendSmtpEmail.new(
      sender: { email: ENV['MAILER_SENDER'], name: "まいにち前屈" },
      to: [{ email: @resource.email }],
      subject: "パスワードの再設定について",
      html_content: html_content
    )

    begin
      api_instance.send_transac_email(send_smtp_email)
    rescue Brevo::ApiError => e
      Rails.logger.error "Brevo password reset email failed: #{e}"
    end
  end
end

require "brevo"

class BrevoMailer < Devise::Mailer
  default from: ENV["MAILER_SENDER"]

  def confirmation_instructions(record, token, opts = {})
    @token = token
    @resource = record

    @confirmation_url = user_confirmation_url(confirmation_token: @token)

    html_content = <<~HTML
      <p>こんにちは #{@resource.email} さん、</p>
      <p>以下のリンクをクリックして、メールアドレスの本人確認を完了してください。あなたが希望していない場合、このメールは無視してください。</p>
      <p><a href="#{@confirmation_url}">メールアドレス確認を完了する</a></p>
    HTML

    mail(
      to: @resource.email,
      subject: "メールアドレスの確認",
      body: html_content,
      content_type: "text/html"
    )
  end

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record

    @reset_url = edit_user_password_url(reset_password_token: @token)

    html_content = <<~HTML
      <p>こんにちは #{@resource.email} さん、</p>
      <p>誰かがパスワードの再設定を希望しました。次のリンクでパスワードの再設定ができます。</p>
      <p><a href="#{@reset_url}">パスワード変更</a></p>
      <p>あなたが希望していない場合、このメールは無視してください。</p>
      <p>上のリンクにアクセスして新しいパスワードを設定するまで、パスワードは変更されません。</p>
    HTML

    mail(
      to: @resource.email,
      subject: "パスワードの再設定について",
      body: html_content,
      content_type: "text/html"
    )
  end
end

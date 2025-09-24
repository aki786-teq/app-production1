# Brevo API を使うためのカスタムデリバリーメソッド
class BrevoDeliveryMethod
  def initialize(settings)
    # この初期化子はAction Mailerに要求されますが、今回は使いません
  end

  def deliver!(mail)
    Brevo.configure do |config|
      config.api_key["api-key"] = ENV["BREVO_API_KEY"]
    end
    api_instance = Brevo::TransactionalEmailsApi.new

    send_smtp_email = Brevo::SendSmtpEmail.new(
      sender: { email: mail.from.first, name: "まいにち前屈" },
      to: mail.to.map { |email| { email: email } },
      subject: mail.subject,
      html_content: mail.body.raw_source
    )

    api_instance.send_transac_email(send_smtp_email)
  rescue Brevo::ApiError => e
    Rails.logger.error "Brevo email failed: #{e}"
  end
end

ActionMailer::Base.add_delivery_method :brevo, BrevoDeliveryMethod

# OmniAuthの初期化設定
Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"]

  # LINE Login
  provider :line, ENV["LINE_KEY"], ENV["LINE_SECRET"]

  # CSRF保護を有効化
  OmniAuth.config.allowed_request_methods = [ :get, :post ]
end

# OmniAuthのパスプレフィックスを設定
OmniAuth.config.path_prefix = "/users/auth"

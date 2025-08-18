RSpec.configure do |config|
  # JS を使わないシステムスペックは rack_test で実行（Selenium/Chrome 不要）
  config.before(:each, type: :system) do
    driven_by(:rack_test)
  end

  # JS が必要な場合のみ headless chrome を使う
  config.before(:each, type: :system, js: true) do
    driven_by(:selenium_chrome_headless)
  end
end



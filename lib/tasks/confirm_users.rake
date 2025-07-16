namespace :user do
  desc "Confirm all unconfirmed users"
  task confirm_all: :environment do
    users = User.where(confirmed_at: nil)
    count = users.update_all(confirmed_at: Time.current)
    puts "#{count} user(s) confirmed."
  end
end
class Notification < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :user

  enum :action_type, { cheer: 0 }
end

class AddYoutubeLinkToBoards < ActiveRecord::Migration[7.2]
  def change
    add_column :boards, :youtube_link, :string
  end
end

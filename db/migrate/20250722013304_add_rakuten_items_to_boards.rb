class AddRakutenItemsToBoards < ActiveRecord::Migration[7.2]
  def change
    add_column :boards, :item_code, :string
    add_column :boards, :item_name, :string
    add_column :boards, :item_price, :integer
    add_column :boards, :item_url, :text
    add_column :boards, :item_image_url, :text
  end
end

class AddFbImageHeaderToLink < ActiveRecord::Migration
  def up
    add_column :links, :image, :string, default: ""
  end
  def down
    remove_column :links, :image
  end
end

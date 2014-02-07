class AddUserToLinks < ActiveRecord::Migration
  def up
    change_table :links do |t|
      t.belongs_to :user
    end
  end

  def down
    remove_column :links, :user_id
  end
end

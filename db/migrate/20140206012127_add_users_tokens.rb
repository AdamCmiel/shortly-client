class AddUsersTokens < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string :username
      t.string :password
      t.timestamps
    end
    create_table :tokens do |t|
      t.string :auth_code
      t.timestamps
      t.belongs_to :user
    end
  end
  def down
    drop_table :users
    drop_table :tokens
  end
end

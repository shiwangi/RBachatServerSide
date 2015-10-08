class CreateTalkTimePlans < ActiveRecord::Migration
  def change
    create_table :talk_time_plans do |t|
      t.string :validity
      t.float :price
      t.string :name
      t.string :description
      t.string :operator
      t.string :state
      t.float :balance

      t.timestamps null: false
    end
  end
end

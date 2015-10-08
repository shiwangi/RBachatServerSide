class CreateRateCutterPlans < ActiveRecord::Migration
  def change
    create_table :rate_cutter_plans do |t|
      t.string :validity
      t.float :price
      t.string :name
      t.string :description
      t.string :operator
      t.string :state
      t.float :minutesFree
      t.float :ratePerMinute
      t.float :local
      t.float :sameOperator

      t.timestamps null: false
    end
  end
end

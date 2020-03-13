class CreateBuyingGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :buying_groups do |t|
      t.string :name

      t.timestamps
    end
  end
end

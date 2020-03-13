class CreateNotes < ActiveRecord::Migration[6.0]
  def change
    create_table :notes do |t|
      t.text :message
      t.integer :notable_id
      t.string :notable_type
      t.timestamps
    end

    add_index :notes, :notable_id
    add_index :notes, :notable_type
  end
end

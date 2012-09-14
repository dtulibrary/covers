class CreateUsers < ActiveRecord::Migration
  
  def change
    create_table :users,:id=>false do |t|
      t.string :api_key,:primary=>true
      t.string :sn
      t.string :ln
      t.integer :default_height
      t.integer :default_width
      t.integer :on_missing_image
      t.integer :on_missing_title
      t.timestamps
    end
  end
end

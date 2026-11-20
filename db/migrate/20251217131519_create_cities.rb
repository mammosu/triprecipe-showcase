class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.string :name_ja, null: false
      t.string :name_en
      t.string :country_code, limit: 2
      t.string :slug, null: false
      t.text :aliases, null: false, default: "[]"

      t.timestamps
    end

    add_index :cities, :slug, unique: true
    add_index :cities, :country_code
  end
end

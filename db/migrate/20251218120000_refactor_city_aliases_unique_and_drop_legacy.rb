class RefactorCityAliasesUniqueAndDropLegacy < ActiveRecord::Migration[8.1]
  def change
    remove_column :cities, :aliases, :text, default: "[]", null: false if column_exists?(:cities, :aliases)

    if index_exists?(:city_aliases, [ :city_id, :normalized_name ], unique: true)
      remove_index :city_aliases, column: [ :city_id, :normalized_name ]
    end

    unless index_exists?(:city_aliases, :normalized_name, unique: true)
      remove_index :city_aliases, :normalized_name if index_exists?(:city_aliases, :normalized_name)
      add_index :city_aliases, :normalized_name, unique: true
    end

    add_index :city_aliases, :city_id unless index_exists?(:city_aliases, :city_id)
  end
end

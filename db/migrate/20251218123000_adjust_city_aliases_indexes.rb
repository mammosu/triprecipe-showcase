class AdjustCityAliasesIndexes < ActiveRecord::Migration[8.1]
  def change
    if index_exists?(:city_aliases, :normalized_name, unique: true)
      remove_index :city_aliases, column: :normalized_name
    end

    unless index_exists?(:city_aliases, [ :city_id, :normalized_name ], unique: true)
      add_index :city_aliases, [ :city_id, :normalized_name ], unique: true
    end

    add_index :city_aliases, :normalized_name unless index_exists?(:city_aliases, :normalized_name)
  end
end

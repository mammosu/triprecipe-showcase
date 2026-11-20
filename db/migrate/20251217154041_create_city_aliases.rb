class CreateCityAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :city_aliases do |t|
      t.references :city, null: false, foreign_key: true
      t.string :raw_name, null: false
      t.string :normalized_name, null: false

      t.timestamps
    end

    add_index :city_aliases, [ :city_id, :normalized_name ], unique: true
    add_index :city_aliases, :normalized_name

    reversible do |dir|
      dir.up do
        City.reset_column_information
        CityAlias.reset_column_information if defined?(CityAlias)
        say_with_time "Backfilling city aliases" do
          City.find_each do |city|
            values = (Array(city.aliases) + [ city.name_ja, city.name_en, city.slug ]).compact_blank
            normalized_map = {}

            values.each do |value|
              normalized = CityNormalizer.normalize(value)
              next if normalized.blank? || normalized_map.key?(normalized)

              normalized_map[normalized] = value
            end

            normalized_map.each do |normalized, value|
              CityAlias.create!(
                city: city,
                raw_name: value,
                normalized_name: normalized
              )
            rescue ActiveRecord::RecordNotUnique
              # 別都市ですでに登録済みの場合はスキップ（国名などの共有エイリアスを許容）
              next
            end
          end
        end
      end
    end
  end
end

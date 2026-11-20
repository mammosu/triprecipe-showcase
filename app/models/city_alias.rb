class CityAlias < ApplicationRecord
  belongs_to :city

  validates :raw_name, presence: true
  validates :normalized_name, presence: true, uniqueness: { scope: :city_id }
end

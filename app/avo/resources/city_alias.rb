class Avo::Resources::CityAlias < Avo::BaseResource
  self.authorization_policy = AdminPolicy

  def fields
    field :id, as: :id
    field :city, as: :belongs_to
    field :raw_name, as: :text
    field :normalized_name, as: :text
  end
end

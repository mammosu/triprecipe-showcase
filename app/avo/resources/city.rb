class Avo::Resources::City < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  self.title = :name_ja

  def fields
    field :id, as: :id
    field :slug, as: :text
    field :name_ja, as: :text
    field :name_en, as: :text
    field :country_code, as: :text
    field :recipes, as: :has_many
  end
end

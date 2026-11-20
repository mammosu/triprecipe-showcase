class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :email, as: :text
    field :recipes, as: :has_many
    field :saved_recipes, as: :has_many
    field :favorite_recipes, as: :has_many, through: :saved_recipes
    field :recipe_collaborations, as: :has_many
    field :collaborated_recipes, as: :has_many, through: :recipe_collaborations
  end
end

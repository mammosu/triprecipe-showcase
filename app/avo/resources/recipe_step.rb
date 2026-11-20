class Avo::Resources::RecipeStep < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :recipe_day, as: :belongs_to
    field :title, as: :text
    field :category, as: :text
    field :starts_at, as: :date_time
    field :ends_at, as: :date_time
    field :position, as: :number
    field :notes, as: :textarea
    field :photos_state, as: :textarea
    field :photos, as: :files
  end
end

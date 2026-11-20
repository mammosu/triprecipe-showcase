class Avo::Resources::RecipeDay < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :recipe, as: :belongs_to
    field :day_order, as: :number, name: "Day number"
    field :title, as: :text
    field :starts_on, as: :date
    field :notes, as: :textarea
  end
end

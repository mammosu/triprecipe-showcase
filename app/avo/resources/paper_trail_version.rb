class Avo::Resources::PaperTrailVersion < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  # self.includes = []
  # self.attachments = []
  self.model_class = ::PaperTrail::Version
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :item_type, as: :text
    field :item_id, as: :number
    field :event, as: :text
    field :whodunnit, as: :text
    field :actor_email, as: :text
    field :object_changes, as: :code
    field :created_at, as: :date_time
    field :item, as: :belongs_to, polymorphic_as: :item, types: [ RecipeStep, RecipeDay, Recipe ]
  end
end

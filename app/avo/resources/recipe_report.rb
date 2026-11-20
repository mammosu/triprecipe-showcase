class Avo::Resources::RecipeReport < Avo::BaseResource
  self.authorization_policy = AdminPolicy

  def fields
    field :id, as: :id
    field :recipe, as: :belongs_to
    field :user, as: :belongs_to
    field :reason, as: :select, options: -> { RecipeReport.reasons.keys }, show_on_index: true
    field :comment, as: :textarea, show_on_index: true
    field :status, as: :select, options: -> { RecipeReport.statuses.keys }, show_on_index: true
    field :handled_by_user, as: :belongs_to
    field :created_at, as: :date_time
  end

  def actions
    action Avo::Actions::UnpublishRecipe
  end
end

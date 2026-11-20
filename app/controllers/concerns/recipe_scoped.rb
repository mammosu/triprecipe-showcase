module RecipeScoped
  extend ActiveSupport::Concern

  included do
    helper_method :owns_recipe?
  end

  private

  def set_recipe
    identifier = recipe_identifier

    # Try to eager-load associations commonly used on the show page to avoid N+1 queries.
    # If identifier looks like a numeric id, fall back to find to preserve legacy numeric URLs.
    @recipe = Recipe.includes(
      :user,
      { forked_from_recipe: :user },
      { cover_image_attachment: :blob },
      { recipe_days: { recipe_steps: [ { photos_attachments: :blob } ] } },
      { recipe_share_tokens: :access_logs }
    ).find_by(slug: identifier)
    @recipe ||= Recipe.fetch_by_slug!(identifier)
  end

  def recipe_identifier
    params[recipe_param_key]
  end

  def recipe_param_key
    :recipe_id
  end

  def authorize_visibility!(plan = @recipe)
    return if plan.public? || owns_recipe?(plan) || collaborator?(plan) || share_link_access_granted?

    redirect_to recipes_path, alert: "閲覧権限がありません。"
  end

  def owns_recipe?(plan = @recipe)
    user_signed_in? && plan.present? && plan.user_id == current_user.id
  end

  def collaborator?(plan = @recipe)
    return false unless user_signed_in? && plan.present?
    plan.recipe_collaborators.exists?(user_id: current_user.id)
  end

  def share_link_access_granted?
    defined?(@share_link_access_granted) && @share_link_access_granted
  end
end

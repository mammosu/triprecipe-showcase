class RecipeIndexService
  def self.call(user, limit: nil, filters: {})
    result = {}
    # Eager-load associations used by the index page and plan cards to avoid N+1 queries.
    # - `plan_card` expects `plan.user` and may display `favorites_count` from scopes.
    public_q = Recipe.includes(:user, :city, :tags).with_attached_cover_image.where(public: true).with_favorites_count.order(created_at: :desc)
    public_q = apply_filters(public_q, filters)
    public_q = public_q.limit(limit) if limit.present?
    result[:public_recipes] = public_q
    # Popular plans should include user and favorite-count data too.
    popular_q = Recipe.popular_plans(limit: 5).includes(:user, :city, :tags).with_attached_cover_image.with_favorites_count
    popular_q = popular_q.limit(limit) if limit.present?
    result[:popular_recipes] = popular_q

    if user.present?
      # For a signed-in user include lightweight associations used in cards.
      my_q = user.recipes.includes(:user, :city, :tags).with_attached_cover_image.order(created_at: :desc)
      my_q = my_q.limit(limit) if limit.present?
      result[:my_recipes] = my_q
      # Build favorite recipes via an explicit join to saved_recipes so ordering
      # by saved_recipes.created_at and visibility filtering work reliably
      fav_q = Recipe
           .joins(:saved_recipes)
           .where(saved_recipes: { user_id: user.id })
           .includes(:user, :city, :tags)
           .with_attached_cover_image
           .merge(Recipe.visible_to(user).with_favorites_count)
           .order("saved_recipes.created_at DESC")
           .distinct
      # Log SQL for debugging failing spec (temporary)
      Rails.logger.debug("[RecipeIndexService] favorite SQL: #{fav_q.to_sql}")
      fav_q = fav_q.limit(limit) if limit.present?
      result[:favorite_recipes] = fav_q
    end

    result
  end

  def self.apply_filters(scope, filters)
    return scope if filters.blank?

    city_filter = filters[:city_id]
    query = filters[:query]
    tag_keys = Array(filters[:tags]).presence || Array(filters[:tag]).presence
    tag_keys = Array(tag_keys).map(&:presence).compact

    filtered_scope = scope

    if city_filter.present?
      filtered_scope = filtered_scope.with_city_id(city_filter)

      # When both a city and a query are present, apply both filters.
      filtered_scope = filtered_scope.keyword_search(query) if query.present?
    else
      # Preserve existing behavior: if no city filter is present, always apply
      # keyword_search with the given query (even if it is blank or nil).
      filtered_scope = filtered_scope.keyword_search(query)
    end

    if tag_keys.present?
      filtered_scope = filtered_scope.joins(:tags).where(tags: { key: tag_keys }).distinct
    end

    filtered_scope
  end
end

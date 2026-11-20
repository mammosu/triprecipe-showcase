class RecipesController < ApplicationController
  include RecipeScoped

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_recipe, only: %i[show edit update destroy fork]
  before_action :load_share_token_from_service, only: :show
  before_action :authorize_visibility!, only: :show
  before_action :set_index_vars, only: :index
  before_action :load_active_tags, only: %i[index new edit create update]


  def index
    # インスタンス変数は before_action `set_index_vars` によって準備されます
  end

  def show
    if params[:id] != @recipe.to_param
      redirect_params = {}
      redirect_params[:share_token] = params[:share_token] if params[:share_token].present?
      return redirect_to recipe_url(@recipe, redirect_params), status: :moved_permanently
    end

    @recipe_days = @recipe.recipe_days.includes(:recipe_steps)
    @recipe_saved = @recipe.saved_by?(current_user)
    log_recipe_view_event
    return unless owns_recipe?

    @active_share_token = @recipe.active_share_token
    @share_token_history = @recipe.recipe_share_tokens.includes(:access_logs).order(created_at: :desc)
  end

  def new
    @recipe = current_user.recipes.build(public: true)
  end

  def create
    result = RecipeCreateService.call(current_user, recipe_params)

    @recipe = result[:recipe]
    if result[:success]
      redirect_to @recipe, notice: "旅行レシピを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @recipe
  end

  def update
    authorize @recipe
    result = RecipeUpdateService.call(@recipe, recipe_params, editor: current_user)

    @recipe = result[:recipe]
    if result[:success]
      @recipe.send(:purge_cover_image_if_marked!)
      redirect_to @recipe, notice: "旅行レシピを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @recipe
    @recipe.destroy
    redirect_to recipes_path, notice: "旅行レシピを削除しました。"
  end

  def fork
    if session[:last_forked_recipe_id] == @recipe.id && session[:last_forked_at].present? && Time.zone.parse(session[:last_forked_at]) > 10.seconds.ago
      return redirect_to recipe_path(@recipe), alert: "レシピのコピー処理中です。しばらくお待ちください。"
    end

    authorize @recipe, :fork?
    result = RecipeForkService.call(@recipe, current_user)

    if result[:success]
      session[:last_forked_recipe_id] = @recipe.id
      session[:last_forked_at] = Time.current.iso8601

      EventLogger.log!(event_type: "recipe_fork", recipe: @recipe, actor: current_user, metadata: { source_recipe_id: @recipe.id })
      redirect_to result[:recipe], notice: "レシピをコピーしました。"
    else
      redirect_back fallback_location: recipe_path(@recipe), alert: "レシピのコピーに失敗しました。"
    end
  end

  private


  def recipe_param_key
    :id
  end

  def recipe_params
    permitted = params.require(:recipe).permit(:title, :city_display, :city_id, :days_count, :description, :public, :cover_image, :remove_cover_image, tag_ids: [])
    if permitted[:tag_ids].present?
      permitted[:tag_ids] = Tag.active.where(id: permitted[:tag_ids]).pluck(:id)
    end
    permitted
  end
  def set_index_vars
    filters = recipe_search_params.to_h.compact_blank.symbolize_keys
    @city_filter = filters[:city_id]
    @city_filter_display = filters[:city_display]
    @query = filters[:query]
    raw_tags = Array(filters[:tags]).presence || (filters[:tag].present? ? [ filters[:tag] ] : [])
    @tag_filters = Array(raw_tags).compact_blank

    vars = RecipeIndexService.call(current_user, filters: filters)

    # Debug: log favorite query and titles in test runs
    if Rails.env.test?
      begin
        Rails.logger.debug("[RecipesController] favorite SQL: #{vars[:favorite_recipes]&.to_sql}")
        titles = vars[:favorite_recipes]&.limit(10)&.pluck(:title)
        Rails.logger.debug("[RecipesController] favorite titles: #{titles.inspect}")
      rescue => e
        Rails.logger.debug("[RecipesController] favorite debug error: #{e.message}")
      end
    end

    #  インデックスページ用にコレクションをページ分割し、巨大な結果セットの読み込みを回避する。
    # 表示件数設定はデフォルト値であり、調整可能です
    @pagy_public, @public_recipes = pagy(vars[:public_recipes] || Recipe.none, items: 20)
    @pagy_popular, @popular_recipes = pagy(vars[:popular_recipes] || Recipe.none, items: 5)
    @pagy_my, @my_recipes = pagy(vars[:my_recipes] || Recipe.none, items: 20)
    @pagy_fav, @favorite_recipes = pagy(vars[:favorite_recipes] || Recipe.none, items: 20)
  end

  def recipe_search_params
    params.permit(:city_id, :city_display, :query, :tag, tags: [])
  end

  def load_active_tags
    @active_tags = Tag.active
  end

  def load_share_token_from_service
    result = RecipeShareTokenService.load_and_log(@recipe, params[:share_token], request)
    return if result.blank?

    @share_token = result[:share_token]
    @share_link_access_granted = result[:share_link_access_granted]
  end

  def log_recipe_view_event
    return if request.headers["Purpose"] == "prefetch" || request.headers["Sec-Purpose"] == "prefetch"
    return if @view_logged

    metadata = {}
    metadata[:page] = params[:page] if params[:page].present?

    EventLogger.log!(event_type: "recipe_view", recipe: @recipe, actor: current_user, metadata: metadata)

    if @share_token.present?
      EventLogger.log!(event_type: "recipe_share", recipe: @recipe, actor: current_user, metadata: metadata.merge(share_token_id: @share_token.id))
    end

    @view_logged = true
  end
end

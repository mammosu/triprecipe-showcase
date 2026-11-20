class ShareTokensController < ApplicationController
  def show
    share_token = RecipeShareToken.active.find_by!(token: params[:token])
    redirect_to recipe_url(share_token.recipe, share_token: share_token.token)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "共有リンクが無効か、有効期限切れです。"
  end
end

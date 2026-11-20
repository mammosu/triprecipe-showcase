class RecipeShareTokenService
  # token_param: string (params[:share_token])
  # request: controller request object (to read remote_ip and user_agent)
  def self.load_and_log(recipe, token_param, request)
    return {} unless token_param.present?

    share_token = recipe.recipe_share_tokens.active.find_by(token: token_param)
    return {} unless share_token

    begin
      share_token.access_logs.create!(
        accessed_at: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("RecipeShareToken access log failed: #{e.message}")
    end

    # mark the recipe instance so policies can detect share-link access
    begin
      recipe.define_singleton_method(:share_link_access_granted?) { true }
    rescue StandardError
      recipe.instance_variable_set(:@share_link_access_granted, true)
      def recipe.share_link_access_granted?
        !!instance_variable_get(:@share_link_access_granted)
      end
    end

    { share_token: share_token, share_link_access_granted: true }
  end
end

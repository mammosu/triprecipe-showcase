require 'rails_helper'

RSpec.describe 'ShareTokens', type: :request do
  let(:owner) { User.create!(email: "owner_#{SecureRandom.hex}@example.com", password: "password") }
  let(:recipe) { Recipe.create!(title: 'Shared', city_display: 'X', user: owner, public: false) }

  describe 'GET /share/:token' do
    it 'redirects to recipe page with share_token and logs access' do
      token = recipe.recipe_share_tokens.create!

      expect {
        get share_recipe_path(token.token)
        follow_redirect!
      }.to change { RecipeShareAccessLog.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(request.fullpath).to include("share_token=#{token.token}")
    end

    it 'redirects to root with alert when token invalid' do
      get share_recipe_path('nope')
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('共有リンクが無効か、有効期限切れです。')
    end
  end
end

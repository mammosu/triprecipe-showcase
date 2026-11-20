require "rails_helper"
require "nokogiri"

RSpec.describe "Recipes", type: :request do
  let!(:user) do
    User.create!(
      email: "request-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:other_user) do
    User.create!(
      email: "other-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  describe "GET /recipes" do
    let!(:public_plan) do
      Recipe.create!(
        title: "公開レシピ",
        city_display: "パリ",
        days_count: 5,
        description: "公開されている旅程",
        public: true,
        user: other_user
      )
    end

    let!(:private_plan) do
      Recipe.create!(
        title: "非公開レシピ",
        city_display: "ローマ",
        days_count: 4,
        description: "個人用",
        public: false,
        user: user
      )
    end

    it "shows public plans to guests" do
      get recipes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(public_plan.title)
      expect(response.body).not_to include(private_plan.title)
    end

    it "links public plan cards to the detail page with top-level navigation" do
      get recipes_path

      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML.parse(response.body)
      public_link = doc.at_css("a[href='#{recipe_path(public_plan)}']")

      expect(public_link).to be_present
      expect(public_link["data-turbo-frame"]).to eq("_top")
    end

    it "does not expose user email on public pages to guests" do
      get recipes_path

      expect(response).to have_http_status(:ok)
      # Ensure the raw email address of the plan owner is not present
      expect(response.body).not_to include(other_user.email)
      # And on plan detail page
      get recipe_path(public_plan)
      expect(response.body).not_to include(other_user.email)
    end

    it "shows a user's own plans after sign in" do
      sign_in user

      get recipes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(private_plan.title)
    end

    context "popular plans section" do
      let!(:popular_plan1) do
        Recipe.create!(
          title: "人気レシピ1",
          city_display: "東京",
          days_count: 3,
          description: "人気の旅程",
          public: true,
          user: other_user
        )
      end

      let!(:popular_plan2) do
        Recipe.create!(
          title: "人気レシピ2",
          city_display: "大阪",
          days_count: 2,
          description: "人気の旅程2",
          public: true,
          user: other_user
        )
      end

      let!(:private_popular_plan) do
        Recipe.create!(
          title: "非公開人気レシピ",
          city_display: "京都",
          days_count: 3,
          description: "非公開",
          public: false,
          user: other_user
        )
      end

      before do
        # Create favorites for popular plans (within 30 days)
        3.times do |i|
          temp_user = User.create!(
            email: "temp#{i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          )
          SavedRecipe.create!(user: temp_user, recipe: popular_plan1)
        end

        2.times do |i|
          temp_user = User.create!(
            email: "temp_popular2_#{i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          )
          SavedRecipe.create!(user: temp_user, recipe: popular_plan2)
        end

        # Create favorite for private plan (should not appear)
        temp_user = User.create!(
          email: "temp_private@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        SavedRecipe.create!(user: temp_user, recipe: private_popular_plan)
      end

      it "displays popular plans section with favorite counts" do
        get recipes_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("人気のレシピ")
        expect(response.body).to include(popular_plan1.title)
        expect(response.body).to include(popular_plan2.title)
      end

      it "excludes private plans from popular plans" do
        get recipes_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(private_popular_plan.title)
      end

      it "orders popular plans by favorite count" do
        get recipes_path

        expect(response).to have_http_status(:ok)
        # popular_plan1 (3 favorites) should appear before popular_plan2 (2 favorites)
        plan1_pos = response.body.index(popular_plan1.title)
        plan2_pos = response.body.index(popular_plan2.title)
        expect(plan1_pos).to be < plan2_pos
      end

      it "displays favorite count badges in popular plans section" do
        get recipes_path

        expect(response).to have_http_status(:ok)
        # Extract the popular plans section
        popular_section = response.body[/人気のレシピ.*?<\/section>/m]
        expect(popular_section).not_to be_nil

        doc = Nokogiri::HTML(popular_section)
        counts = doc.css("[data-testid='favorite-count-badge']").map do |badge|
          badge.text.scan(/\d+/).first.to_i
        end

        expect(counts).to include(3, 2)
      end
    end

    context "favorite recipes section" do
      let!(:recent_favorite) do
        Recipe.create!(
          title: "最新のお気に入り",
          city_display: "札幌",
          public: true,
          user: other_user
        )
      end

      let!(:older_favorite) do
        Recipe.create!(
          title: "少し前のお気に入り",
          city_display: "沖縄",
          public: true,
          user: other_user
        )
      end

      let!(:hidden_favorite) do
        Recipe.create!(
          title: "非公開に変更されたレシピ",
          city_display: "名古屋",
          public: true,
          user: other_user
        )
      end

      before do
        SavedRecipe.create!(user: user, recipe: older_favorite).update_column(:created_at, 2.days.ago)
        SavedRecipe.create!(user: user, recipe: recent_favorite)
        SavedRecipe.create!(user: user, recipe: hidden_favorite)
        hidden_favorite.update!(public: false)
      end

      it "shows accessible favorites ordered by saved_at desc" do
        sign_in user

        get recipes_path

        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        favorite_panel = doc.css("div.favorite_recipes")
        expect(favorite_panel).not_to be_nil

        favorite_titles = favorite_panel.css("li").map do |li|
          li.at_css("h3.recipe_title")&.text&.strip
        end.compact

        expect(favorite_titles).to eq([ recent_favorite.title, older_favorite.title ])
        expect(favorite_titles).not_to include(hidden_favorite.title)
      end
    end

    context "public gallery favorite badges" do
      let!(:popular_public_plan) do
        Recipe.create!(
          title: "星付きレシピ",
          city_display: "京都",
          public: true,
          user: other_user
        )
      end

      let!(:quiet_public_plan) do
        Recipe.create!(
          title: "まだお気に入りゼロ",
          city_display: "大阪",
          public: true,
          user: other_user
        )
      end

      before do
        2.times do |i|
          temp_user = User.create!(
            email: "gallery_fan_#{i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          )
          SavedRecipe.create!(user: temp_user, recipe: popular_public_plan)
        end
      end

      it "shows favorite count badges only for plans with saves" do
        get recipes_path

        expect(response).to have_http_status(:ok)

        doc = Nokogiri::HTML(response.body)
        gallery_section = doc.css("section").find do |section|
          section.at_css("h2")&.text&.include?("公開レシピギャラリー")
        end
        expect(gallery_section).not_to be_nil

        card_info = gallery_section.css("a").select { |card| card.at_css("h3") }.map do |card|
          title = card.at_css("h3")&.text&.strip
          favorite_badge = card.at_css("[data-testid='favorite-count-badge']")
          count_text = favorite_badge&.text.to_s.scan(/\d+/).first
          [ title, count_text ]
        end

        popular_card = card_info.find { |title, _| title == popular_public_plan.title }
        quiet_card = card_info.find { |title, _| title == quiet_public_plan.title }

        expect(popular_card&.last&.to_i).to eq(2)
        expect(quiet_card&.last).to be_nil
      end
    end
  end

  describe "POST /recipes" do
    let(:params) do
      {
        recipe: {
          title: "新規レシピ",
          city_display: "バルセロナ",
          days_count: 3,
          description: "テスト作成",
          public: true
        }
      }
    end

    it "creates a plan for authenticated users" do
      sign_in user

      expect do
        post recipes_path, params: params
      end.to change(Recipe, :count).by(1)

      expect(response).to redirect_to(recipe_path(Recipe.last))
      follow_redirect!
      expect(response.body).to include("新規レシピ")
    end

    it "redirects guests to the sign-in page" do
      post recipes_path, params: params

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /recipes/:id" do
    it "allows anyone to view a public plan" do
      plan = Recipe.create!(
        title: "公開詳細",
        city_display: "ソウル",
        days_count: 2,
        description: "public",
        public: true,
        user: other_user
      )

      get recipe_path(plan)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("公開詳細")
    end

    it "renders og:image when a cover image is attached" do
      plan = Recipe.create!(
        title: "OGP画像",
        city_display: "大阪",
        days_count: 1,
        description: "cover",
        public: true,
        user: other_user
      )
      plan.cover_image.attach(fixture_file_upload("spec/fixtures/files/cover.png", "image/png"))

      get recipe_path(plan)

      doc = Nokogiri::HTML(response.body)
      og_image = doc.at_css('meta[property="og:image"]')
      twitter_card = doc.at_css('meta[name="twitter:card"]')

      expect(og_image).to be_present
      expect(og_image["content"]).to include("http://www.example.com")
      expect(og_image["content"]).to include("/rails/active_storage/")
      expect(twitter_card["content"]).to eq("summary_large_image")
    end

    it "prevents guests from viewing private plans" do
      plan = Recipe.create!(
        title: "秘密の旅",
        city_display: "札幌",
        days_count: 6,
        description: "private",
        public: false,
        user: other_user
      )

      get recipe_path(plan)

      expect(response).to redirect_to(recipes_path)
    end

    it "allows private plans to be viewed with a share token" do
      plan = Recipe.create!(
        title: "シェア専用",
        city_display: "横浜",
        public: false,
        user: other_user
      )
      share_token = plan.recipe_share_tokens.create!

      expect do
        get recipe_path(plan, params: { share_token: share_token.token })

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("共有リンク経由で表示しています")
      end.to change(RecipeShareAccessLog, :count).by(1)
    end

    it "rejects access with an expired share token" do
      plan = Recipe.create!(
        title: "期限切れシェア",
        city_display: "名古屋",
        public: false,
        user: other_user
      )
      expired_token = plan.recipe_share_tokens.create!(expires_at: 1.day.ago)

      get recipe_path(plan, params: { share_token: expired_token.token })

      expect(response).to redirect_to(recipes_path)
      expect(flash[:alert]).to include("閲覧権限がありません。")
    end

    it "serves slug URLs and redirects numeric IDs" do
      plan = Recipe.create!(
        title: "slugテスト",
        city_display: "沖縄",
        public: true,
        user: other_user
      )

      get recipe_path(id: plan.slug)

      expect(response).to have_http_status(:ok)

      get "/recipes/#{plan.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "redirects legacy slugs to the latest slug" do
      plan = Recipe.create!(
        title: "Original slug",
        city_display: "Tokyo",
        public: true,
        user: other_user
      )
      old_slug = plan.slug
      plan.update!(title: "Refreshed slug", city_display: "Osaka")

      get recipe_path(id: old_slug)

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["Location"]).to eq(recipe_url(plan))
    end

    it "preserves share_token when redirecting from legacy slug" do
      plan = Recipe.create!(
        title: "Original slug",
        city_display: "Kyoto",
        public: true,
        user: other_user
      )
      old_slug = plan.slug
      plan.update!(title: "New slug", city_display: "Osaka")
      share_token = plan.recipe_share_tokens.create!

      get recipe_path(id: old_slug, params: { share_token: share_token.token })

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["Location"]).to eq(recipe_url(plan, share_token: share_token.token))
    end

    it "preserves share_token when redirecting from numeric ID" do
      plan = Recipe.create!(
        title: "プライベートレシピ",
        city_display: "京都",
        public: false,
        user: other_user
      )
      share_token = plan.recipe_share_tokens.create!

      get "/recipes/#{plan.id}", params: { share_token: share_token.token }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "share token access logging" do
    let!(:owner) do
      User.create!(
        email: "share-owner@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    let!(:recipe) do
      Recipe.create!(title: "共有レシピ", public: false, user: owner)
    end

    let!(:share_token) { recipe.recipe_share_tokens.create! }

    it "creates an access log when visiting with share_token param" do
      expect do
        get recipe_path(recipe, params: { share_token: share_token.token })
      end.to change { share_token.access_logs.count }.by(1)

      log = share_token.access_logs.order(accessed_at: :desc).first
      expect(log.accessed_at).to be_within(5.seconds).of(Time.current)
    end

    it "creates an access log when visiting the short share URL" do
      expect do
        get share_recipe_path(token: share_token.token)
        follow_redirect!
      end.to change { share_token.access_logs.count }.by(1)
    end
  end
end

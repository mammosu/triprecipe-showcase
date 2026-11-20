require "rails_helper"

RSpec.describe "PaperTrail versions" do
  let(:user) { User.create!(email: "pt@example.com", password: "password123", password_confirmation: "password123") }

  it "creates a version on recipe update" do
    recipe = Recipe.create!(title: "PT", user: user, slug: "pt")
    expect { recipe.update!(title: "PT v2") }.to change { recipe.versions.count }.by(1)
    last = recipe.versions.last
    expect(last.changeset["title"]).to eq([ "PT", "PT v2" ])
  end

  it "stores cover_image filename in versions on attach" do
    recipe = Recipe.create!(title: "PT2", user: user, slug: "pt2")

    expect do
      recipe.update!(cover_image: Rack::Test::UploadedFile.new("spec/fixtures/files/cover.png", "image/png"))
    end.to change { recipe.versions.count }.by(1)

    last = recipe.versions.last
    expect(last.changeset["cover_image"]).to eq([ nil, "cover.png" ])
  end

  it "stores attachment removal on destroy" do
    recipe = Recipe.create!(title: "PT3", user: user, slug: "pt3-#{SecureRandom.hex(4)}")
    recipe.update!(cover_image: Rack::Test::UploadedFile.new("spec/fixtures/files/cover.png", "image/png"))

    recipe.destroy!

    destroy_version = recipe.versions.where(event: "destroy").last
    expect(destroy_version).to be_present
    expect(destroy_version.changeset["cover_image"]).to eq([ "cover.png", nil ])
  end
end

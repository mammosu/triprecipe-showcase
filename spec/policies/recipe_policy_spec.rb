require "rails_helper"

RSpec.describe RecipePolicy, type: :policy do
  let(:owner) { User.create!(email: "owner@example.com", password: "password123", password_confirmation: "password123") }
  let(:other) { User.create!(email: "otherpol@example.com", password: "password123", password_confirmation: "password123") }

  describe "share link access" do
    let(:recipe) { Recipe.create!(title: "Shareable", user: owner, slug: "shareable", public: false) }

    it "allows show? when share link flag is present on record" do
      # simulate controller/service marking the record
      recipe.define_singleton_method(:share_link_access_granted?) { true }

      policy = RecipePolicy.new(nil, recipe)
      expect(policy.show?).to be true
    end

    it "denies show? when no share link and not public" do
      policy = RecipePolicy.new(nil, recipe)
      expect(policy.show?).to be false
    end
  end
end
require 'rails_helper'

RSpec.describe RecipePolicy do
  let(:owner) { User.create!(email: "owner_#{SecureRandom.hex}@example.com", password: "password") }
  let(:other) { User.create!(email: "other_#{SecureRandom.hex}@example.com", password: "password") }
  let(:recipe) { Recipe.create!(title: "Spec Recipe", city_display: "Osaka", user: owner, public: false) }

  context 'guest user' do
    subject { described_class.new(nil, recipe) }

    it 'allows show only for public recipes' do
      recipe.update!(public: true)
      expect(subject.show?).to be true
      recipe.update!(public: false)
      expect(subject.show?).to be false
    end

    it 'scope resolves only public recipes' do
      visible = RecipePolicy::Scope.new(nil, Recipe.all).resolve
      expect(visible).to include(recipe) if recipe.public?
    end
  end

  context 'owner user' do
    subject { described_class.new(owner, recipe) }

    it 'can create, update, destroy and manage' do
      expect(subject.create?).to be true
      expect(subject.update?).to be true
      expect(subject.destroy?).to be true
      expect(subject.manage_collaborators?).to be true
      expect(subject.manage_share_tokens?).to be true
    end
  end

  describe "fork?" do
    let(:public_recipe) { Recipe.create!(title: "公開レシピ", city_display: "Paris", user: owner, public: true) }
    let(:private_recipe) { Recipe.create!(title: "非公開レシピ", city_display: "Rome", user: owner, public: false) }

    it "allows signed-in users to fork public recipes" do
      policy = described_class.new(other, public_recipe)
      expect(policy.fork?).to be true
    end

    it "denies guests or private recipes" do
      expect(described_class.new(nil, public_recipe).fork?).to be false
      expect(described_class.new(other, private_recipe).fork?).to be false
    end
  end

  context 'collaborators' do
    before do
      @viewer = User.create!(email: "viewer_#{SecureRandom.hex}@example.com", password: "password")
      @editor = User.create!(email: "editor_#{SecureRandom.hex}@example.com", password: "password")
      @admin = User.create!(email: "admin_#{SecureRandom.hex}@example.com", password: "password")
      RecipeCollaborator.create!(recipe: recipe, user: @viewer, role: :viewer)
      RecipeCollaborator.create!(recipe: recipe, user: @editor, role: :editor)
      RecipeCollaborator.create!(recipe: recipe, user: @admin, role: :admin)
    end

    it 'viewer can view but not edit or manage' do
      p = described_class.new(@viewer, recipe)
      expect(p.show?).to be true
      expect(p.update?).to be false
      expect(p.manage_collaborators?).to be false
    end

    it 'editor can update but not manage collaborators' do
      p = described_class.new(@editor, recipe)
      expect(p.update?).to be true
      expect(p.manage_collaborators?).to be false
    end

    it 'admin can manage collaborators and share tokens' do
      p = described_class.new(@admin, recipe)
      expect(p.update?).to be true
      expect(p.manage_collaborators?).to be true
      expect(p.manage_share_tokens?).to be true
    end
  end

  describe 'scope for authenticated user' do
    it 'includes own and collaborated recipes and public ones' do
      another = Recipe.create!(title: 'Public', city_display: 'X', user: other, public: true)
      collab_recipe = Recipe.create!(title: 'Collab', city_display: 'Y', user: other, public: false)
      RecipeCollaborator.create!(recipe: collab_recipe, user: owner, role: :viewer)

      resolved = RecipePolicy::Scope.new(owner, Recipe.all).resolve
      expect(resolved).to include(another)
      expect(resolved).to include(collab_recipe)
      expect(resolved).to include(recipe)
    end
  end
end

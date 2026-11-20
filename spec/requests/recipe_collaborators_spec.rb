require 'rails_helper'

RSpec.describe "RecipeCollaborators", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe) { create(:recipe, user: owner) }

  before do
    sign_in owner
  end

  describe 'POST create' do
    context 'inviting an existing user by email' do
      it 'creates a collaborator associated with user' do
        post recipe_collaborators_path(recipe), params: { recipe_collaborator: { invite_email: other_user.email, role: 'viewer' } }
        expect(response).to redirect_to(recipe_collaborators_path(recipe))
        collab = recipe.reload.recipe_collaborators.find_by(user_id: other_user.id)
        expect(collab).to be_present
        expect(collab.invite_email).to be_blank
      end
    end

    context 'inviting by email for unregistered user' do
      let(:email) { 'newperson@example.com' }

      it 'creates a collaborator with invite_email and sends email' do
        perform_enqueued_jobs do
          expect { post recipe_collaborators_path(recipe), params: { recipe_collaborator: { invite_email: email, role: 'viewer' } } }
            .to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        collab = recipe.reload.recipe_collaborators.find_by(invite_email: email)
        expect(collab).to be_present
        expect(collab.user).to be_nil
      end
    end

    context 'unauthorized user cannot invite' do
      it 'returns forbidden for non-owner/non-admin' do
        sign_out owner
        sign_in other_user
        post recipe_collaborators_path(recipe), params: { recipe_collaborator: { invite_email: 'a@b.com', role: 'viewer' } }
        expect(response).to redirect_to(recipes_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end

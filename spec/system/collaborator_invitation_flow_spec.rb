require 'rails_helper'

RSpec.describe 'Collaborator invitation flow', type: :system do
  include Warden::Test::Helpers
  include ActiveJob::TestHelper

  before do
    driven_by :rack_test
    Warden.test_mode!
  end

  after do
    Warden.test_reset!
  end

  let(:owner) { create(:user, email: 'owner@example.com') }
  let(:recipe) { create(:recipe, user: owner) }
  let(:invite_email) { 'newuser@example.com' }

  it 'owner invites by email, invitee signs up and accepts invitation' do
    # Owner signs in and invites (use Warden helper in system specs)
    login_as(owner, scope: :user)
    visit recipe_collaborators_path(recipe)

    fill_in 'recipe_collaborator_invite_email', with: invite_email
    select '閲覧者', from: 'recipe_collaborator_role'
    perform_enqueued_jobs do
      click_button '招待を送信'
    end

    expect(page).to have_content('コラボレーターを招待しました。')

    collab = recipe.reload.recipe_collaborators.find_by(invite_email: invite_email)
    expect(collab).to be_present

    # Check that an email was sent containing the invitation link
    mail = ActionMailer::Base.deliveries.last
    expect(mail).to be_present
    expect(mail.to).to include(invite_email)
    # extract link from email body
    link = mail.body.to_s[/https?:\/\/[^\s]+/]
    expect(link).to be_present

    # Simulate the invitee visiting the invitation link (signup required)
    visit link
    # invitation show requires login; should redirect to sign in
    expect(page).to have_current_path(new_user_session_path)

    # Simulate the invitee registering externally, then signing in
    invited_user = create(:user, email: invite_email)
    login_as(invited_user, scope: :user)

    # Visit invitation link and accept
    visit link
    expect(page).to have_content('レシピへの招待')
    click_button '承認する'

    collab.reload
    expect(collab.accepted?).to be true
    expect(collab.user.email).to eq(invite_email)
  end
end

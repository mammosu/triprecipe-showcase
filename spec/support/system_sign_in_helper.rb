module SystemSignInHelper
  def sign_in_as(user)
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "PASSWORD", with: "password123"
    click_button "ログイン"
  end
end

RSpec.configure do |config|
  config.include SystemSignInHelper, type: :system
end

require "ostruct"

require "pagy"

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization
  include PaperTrail::Rails::Controller

  # Basic認証（本番環境のみ）を有効化する場合は、以下のコメントアウトを外してください。
  # before_action :basic_auth if Rails.env.production?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  around_action :set_current_user
  before_action :set_paper_trail_whodunnit

  private

  def user_not_authorized
    redirect_to recipes_path, alert: "操作する権限がありません。"
  end

  def set_current_user
    Current.user = current_user
    yield
  ensure
    Current.user = nil
  end

  # PaperTrail: store user id as whodunnit
  def user_for_paper_trail
    current_user&.id
  end

  # PaperTrail: additional info (email) for future use if metadata column is added
  def info_for_paper_trail
    { actor_email: current_user&.email }
  end

  def basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV["BASIC_AUTH_USER"] && password == ENV["BASIC_AUTH_PASSWORD"]
    end
  end
end

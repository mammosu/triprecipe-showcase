# frozen_string_literal: true

class AdminPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  def search?
    admin?
  end

  def upload_cover_image?
    admin?
  end

  def delete_cover_image?
    admin?
  end

  def download_cover_image?
    admin?
  end

  def upload_photos?
    admin?
  end

  def delete_photos?
    admin?
  end

  def download_photos?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.admin?

      scope.all
    end
  end

  private

  def admin?
    user&.admin?
  end
end

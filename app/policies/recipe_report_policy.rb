class RecipeReportPolicy < ApplicationPolicy
  def create?
    user.present? && record.recipe&.public?
  end
end

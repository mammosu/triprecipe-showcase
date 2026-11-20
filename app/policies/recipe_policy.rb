# frozen_string_literal: true

class RecipePolicy < ApplicationPolicy
  # Scope defines which recipes a user can see
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user
        # User can see: public recipes, their own recipes, and recipes they collaborate on
        # Build the OR condition with Arel to avoid raw SQL while keeping a single joined relation
        joined = scope.left_joins(:recipe_collaborators)
        recipes_table = Recipe.arel_table
        collabs_table = RecipeCollaborator.arel_table
        condition = recipes_table[:public].eq(true)
                    .or(recipes_table[:user_id].eq(user.id))
                    .or(collabs_table[:user_id].eq(user.id))

        joined.where(condition).distinct
      else
        # Guest users can only see public recipes
        scope.where(public: true)
      end
    end
  end

  def show?
    # Can view if: recipe is public, user is owner, user is collaborator, or has share token access
    record.public? || owner? || collaborator? || share_link_access?
  end

  def create?
    # Any authenticated user can create recipes
    user.present?
  end

  def update?
    # Can edit if: owner or collaborator with editor/admin role
    owner? || editor_or_admin?
  end

  def destroy?
    # Only owner can delete
    owner?
  end

  def manage_collaborators?
    # Owner or admin collaborators can manage other collaborators
    owner? || admin_collaborator?
  end

  def manage_share_tokens?
    # Owner or admin collaborators can manage share tokens
    owner? || admin_collaborator?
  end

  def fork?
    user.present? && record.public?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end

  def collaborator?
    return false unless user.present?
    record.recipe_collaborators.exists?(user: user)
  end

  def editor_or_admin?
    return false unless user.present?
    record.recipe_collaborators.exists?(user: user, role: %w[editor admin])
  end

  def admin_collaborator?
    return false unless user.present?
    record.recipe_collaborators.exists?(user: user, role: "admin")
  end

  def share_link_access?
    # Controller/service may mark the record instance when a valid share token is used.
    # Support both singleton method or instance variable marker.
    if record.respond_to?(:share_link_access_granted?)
      record.share_link_access_granted?
    else
      !!record.instance_variable_get(:@share_link_access_granted)
    end
  end
end

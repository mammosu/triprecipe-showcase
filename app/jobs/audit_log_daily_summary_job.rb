class AuditLogDailySummaryJob < ApplicationJob
  queue_as :mailers

  def perform(since: 24.hours.ago)
    cutoff = since
    Recipe.find_each do |recipe|
      logs = logs_for_recipe(recipe).where("created_at >= ?", cutoff).order(:created_at)
      next if logs.empty?

      recipients_for(recipe).each do |user|
        AuditLogMailer.daily_summary(user, recipe, logs).deliver_now
      end
    end
  rescue => e
    Rails.logger.warn("[AuditLogDailySummaryJob] failed: #{e.class} #{e.message}")
  end

  private

  def logs_for_recipe(recipe)
    day_ids = recipe.recipe_days.pluck(:id)
    step_ids = recipe.recipe_steps.pluck(:id)

    AuditLog.where(item_type: "Recipe", item_id: recipe.id)
            .or(AuditLog.where(item_type: "RecipeDay", item_id: day_ids))
            .or(AuditLog.where(item_type: "RecipeStep", item_id: step_ids))
  end

  def recipients_for(recipe)
    admins = recipe.recipe_collaborators.includes(:user).where(role: :admin).map(&:user)
    ([ recipe.user ] + admins).compact.uniq
  end
end

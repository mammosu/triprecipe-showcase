class AuditLogMailer < ApplicationMailer
  def daily_summary(user, recipe, logs)
    @user = user
    @recipe = recipe
    @logs = logs
    mail(
      to: user.email,
      subject: "[TripRecipe] #{recipe.title} の変更まとめ"
    )
  end
end

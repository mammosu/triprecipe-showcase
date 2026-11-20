class Avo::Actions::UnpublishRecipe < Avo::BaseAction
  self.name = "レシピを非公開にする"
  self.message = I18n.t("recipes.reports.avo.unpublish_message")
  self.confirm_button_label = I18n.t("recipes.reports.avo.unpublish_confirm")
  self.cancel_button_label = I18n.t("recipes.reports.avo.unpublish_cancel")

  def handle(records:, **)
    updated = 0
    resolved = 0
    handler = (context && context[:current_user]) || Current.user

    records.each do |report|
      begin
        RecipeReport.transaction do
          recipe = report.recipe
          if recipe&.public?
            if recipe.update(public: false)
              updated += 1
            else
              Rails.logger.error(
                "Failed to unpublish recipe #{recipe.id}: #{recipe.errors.full_messages.to_sentence}"
              )
            end
          end

          if report.open? || report.reviewing?
            if report.update(status: :resolved, handled_by_user: handler)
              resolved += 1
            else
              Rails.logger.error(
                "Failed to resolve recipe report #{report.id}: #{report.errors.full_messages.to_sentence}"
              )
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error(
          "Failed to process recipe report #{report.id}: #{e.class} #{e.message}"
        )
      end
    end

    succeed "レシピを非公開にしました (#{updated}件) / 通報を解決にしました (#{resolved}件)"
  end
end

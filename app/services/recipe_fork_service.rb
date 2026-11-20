class RecipeForkService
  def self.call(source_recipe, user)
    forked_recipe = nil

    previous_paper_trail_enabled = PaperTrail.request.enabled?
    begin
      PaperTrail.request(enabled: false) do
        Current.audit_suppressed = true
        Recipe.transaction do
          forked_recipe = source_recipe.dup
          forked_recipe.assign_attributes(
            user: user,
            public: false,
            forked_from_recipe: source_recipe,
            slug: RecipeSlugService.generate_unique_fork_slug_for(source_recipe),
            last_edited_by: user,
            last_edited_by_email: user.email
          )
          forked_recipe.save!

          source_recipe.recipe_days.order(:day_order).each do |day|
            new_day = day.dup
            new_day.assign_attributes(
              recipe: forked_recipe,
              day_order: day.day_order,
              last_edited_by: user,
              last_edited_by_email: user.email
            )
            new_day.save!

            day.recipe_steps.order(:position).each do |step|
              new_step = step.dup
              new_step.assign_attributes(
                recipe_day: new_day,
                position: step.position,
                photos_state: nil,
                last_edited_by: user,
                last_edited_by_email: user.email
              )
              new_step.save!
            end
          end
        end
      end
    ensure
      Current.audit_suppressed = false
      PaperTrail.request.enabled = previous_paper_trail_enabled
    end

    begin
      log_fork_audit!(forked_recipe, source_recipe, user)
      record_fork_version!(forked_recipe, source_recipe, user)
    rescue StandardError => e
      Rails.logger.warn("[RecipeForkService] audit/version record failed: #{e.class} #{e.message}")
    end

    { success: true, recipe: forked_recipe }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, recipe: forked_recipe, error: e }
  end

  def self.log_fork_audit!(forked_recipe, source_recipe, user)
    AuditLogJob.perform_later(
      item_type: "Recipe",
      item_id: forked_recipe.id,
      action: "fork",
      whodunnit: user&.id,
      metadata: {
        forked_from_recipe_id: source_recipe.id,
        forked_from_slug: source_recipe.slug,
        actor_email: user&.email
      }.compact
    )
  end

  def self.record_fork_version!(forked_recipe, source_recipe, user)
    serializer = PaperTrail.serializer
    PaperTrail::Version.create!(
      item_type: "Recipe",
      item_id: forked_recipe.id,
      event: "fork",
      whodunnit: user&.id&.to_s,
      actor_email: user&.email,
      object_changes: serializer.dump(
        {
          "forked_from_recipe_id" => [ nil, source_recipe.id ],
          "public" => [ nil, false ]
        }
      )
    )
  rescue => e
    Rails.logger.warn("[RecipeForkService] version record failed: #{e.class} #{e.message}")
  end
end

class RecipeStepPhotosService
  class << self
    def attach!(step:, files:, actor:)
      return [] if files.blank?

      attachments = PaperTrail.request(enabled_for_RecipeStep: false) do
        step.photos.attach(files)
      end
      added = attachments_metadata(attachments)
      with_paper_trail_actor(actor) do
        step.sync_photos_state!(paper_trail_event: "photos_attach")
      end
      log_added(step: step, added: added, actor: actor)
      attachments
    end

    def purge!(step:, attachment:, actor:)
      removed = attachment_metadata(attachment)
      PaperTrail.request(enabled_for_RecipeStep: false) do
        attachment.purge
      end
      with_paper_trail_actor(actor) do
        step.sync_photos_state!(paper_trail_event: "photos_purge")
      end
      log_removed(step: step, removed: removed, actor: actor)
      removed
    end

    private

    def with_paper_trail_actor(actor)
      return yield if actor.blank?

      PaperTrail.request(
        whodunnit: actor.id.to_s,
        controller_info: { actor_email: actor.email }
      ) { yield }
    end

    def log_added(step:, added:, actor:)
      AuditLogJob.perform_later(
        item_type: "RecipeStep",
        item_id: step.id,
        action: "recipe_step.photos_added",
        whodunnit: actor&.id,
        metadata: {
          step_id: step.id,
          recipe_id: step.recipe_day&.recipe_id,
          day_id: step.recipe_day_id,
          added: added
        }.compact
      )
    end

    def log_removed(step:, removed:, actor:)
      AuditLogJob.perform_later(
        item_type: "RecipeStep",
        item_id: step.id,
        action: "recipe_step.photo_removed",
        whodunnit: actor&.id,
        metadata: {
          step_id: step.id,
          recipe_id: step.recipe_day&.recipe_id,
          day_id: step.recipe_day_id,
          removed: removed
        }.compact
      )
    end

    def attachments_metadata(attachments)
      attachment_ids = Array(attachments).map(&:id).compact
      return [] if attachment_ids.blank?

      ActiveStorage::Attachment
        .where(id: attachment_ids)
        .includes(:blob)
        .map { |attachment| attachment_metadata(attachment) }
        .compact
    end

    def attachment_metadata(attachment)
      blob = attachment&.blob
      return nil if attachment.blank? || blob.blank?

      {
        attachment_id: attachment.id,
        blob_id: attachment.blob_id,
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        byte_size: blob.byte_size
      }
    end
  end
end

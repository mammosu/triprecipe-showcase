class RecipeStep < ApplicationRecord
  MAX_TITLE_LENGTH = 100
  MAX_NOTES_LENGTH = 2000
  CATEGORIES = %w[activity food move stay other].freeze

  PHOTO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_PHOTO_SIZE = 5.megabytes
  MAX_PHOTOS_COUNT = 3

  belongs_to :recipe_day
  belongs_to :last_edited_by, class_name: "User", optional: true
  include Auditable
  has_many_attached :photos
  has_paper_trail only: %i[title notes category starts_at ends_at position photos_state]

  acts_as_list scope: :recipe_day, column: :position

  validates :title, presence: true, length: { maximum: MAX_TITLE_LENGTH }
  validates :starts_at, presence: true
  validates :ends_at,
            comparison: { greater_than_or_equal_to: :starts_at },
            allow_nil: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :notes, length: { maximum: MAX_NOTES_LENGTH }, allow_blank: true
  validates :last_edited_by_email, length: { maximum: 255 }, allow_blank: true
  validate :photos_content_type
  validate :photos_size
  validate :photos_count_within_limit

  scope :ordered, -> { order(:position) }

  def compute_photos_state
    photos.attachments.includes(:blob).map do |att|
      next if att.blob.blank?

      {
        attachment_id: att.id,
        blob_id: att.blob_id,
        filename: att.blob.filename.to_s,
        content_type: att.blob.content_type,
        byte_size: att.blob.byte_size
      }
    end.compact.sort_by { |h| [ h[:blob_id].to_i, h[:attachment_id].to_i ] }
  end

  def sync_photos_state!(paper_trail_event: nil)
    new_state = compute_photos_state.to_json
    return if new_state == photos_state

    self.paper_trail_event = paper_trail_event if paper_trail_event.present?
    update!(photos_state: new_state)
  end

  def photo_metadata_for(attachment)
    blob = attachment.blob
    {
      attachment_id: attachment.id,
      blob_id: attachment.blob_id,
      filename: blob&.filename&.to_s,
      content_type: blob&.content_type,
      byte_size: blob&.byte_size
    }
  end

  def move_up!
    move_higher
  end

  def move_down!
    move_lower
  end

  private

  def photos_content_type
    photos.attachments.each do |attachment|
      next unless attachment.blob

      next if PHOTO_CONTENT_TYPES.include?(attachment.blob.content_type)

      errors.add(:photos, "はPNG/JPEG/WEBP形式の画像を選択してください")
    end
  end

  def photos_size
    photos.attachments.each do |attachment|
      next unless attachment.blob&.byte_size

      if attachment.blob.byte_size > MAX_PHOTO_SIZE
        errors.add(:photos, "は1枚あたり5MB以下にしてください")
      end
    end
  end

  def photos_count_within_limit
    return unless photos.attachments.size > MAX_PHOTOS_COUNT

    errors.add(:photos, "は最大#{MAX_PHOTOS_COUNT}枚までアップロードできます")
  end
end

TimelineItem = RecipeStep

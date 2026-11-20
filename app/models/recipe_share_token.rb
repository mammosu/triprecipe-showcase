class RecipeShareToken < ApplicationRecord
  TOKEN_LENGTH = 24
  DEFAULT_TTL = 30.days

  belongs_to :recipe
  has_many :access_logs, class_name: "RecipeShareAccessLog", dependent: :destroy

  validates :token, presence: true, uniqueness: true

  before_validation :ensure_token, on: :create
  before_create :set_default_expiration

  scope :active, lambda {
    where(revoked_at: nil).where("recipe_share_tokens.expires_at IS NULL OR recipe_share_tokens.expires_at >= ?", Time.current)
  }

  def extend_expiration!(duration: DEFAULT_TTL)
    base_time = expires_at.present? && expires_at.future? ? expires_at : Time.current
    update!(expires_at: base_time + duration)
  end

  def active?
    revoked_at.nil? && (expires_at.blank? || expires_at.future?)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def last_accessed_at
    if access_logs.loaded?
      access_logs.max_by(&:accessed_at)&.accessed_at
    else
      access_logs.order(accessed_at: :desc).limit(1).pick(:accessed_at)
    end
  end

  private

  def ensure_token
    return if token.present?

    max_attempts = 10
    attempts = 0

    loop do
      self.token = SecureRandom.urlsafe_base64((TOKEN_LENGTH * 3) / 4)
      break unless self.class.exists?(token: token)

      attempts += 1
      raise ActiveRecord::RecordNotSaved, "Could not generate unique token" if attempts >= max_attempts
    end
  end

  def set_default_expiration
    self.expires_at ||= DEFAULT_TTL.from_now
  end
end

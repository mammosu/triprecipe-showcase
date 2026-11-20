class RecipeCollaborator < ApplicationRecord
  belongs_to :recipe
  # Support invitations to emails for users who haven't signed up yet.
  # Allow user to be nil for pending email invitations.
  belongs_to :user, optional: true

  # Role enum: viewer can only view, editor can edit, admin can manage collaborators
  enum :role, { viewer: "viewer", editor: "editor", admin: "admin" }, validate: true

  # Validations
  validates :role, presence: true

  # Either a user_id or invite_email must be present
  validate :user_or_email_present

  # Unique constraints: if user exists, ensure not duplicated; if invite_email present, ensure not duplicated for recipe
  validates :user_id, uniqueness: { scope: :recipe_id, message: "is already a collaborator on this recipe" }, if: -> { user_id.present? }
  validates :invite_email, uniqueness: { scope: :recipe_id, message: "has already been invited" }, if: -> { invite_email.present? }

  # Validate invite_email format when present to avoid unsafe values
  validates :invite_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  validate :cannot_add_owner_as_collaborator

  # Scopes
  scope :pending, -> { where.not(invited_at: nil).where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :by_role, ->(role) { where(role: role) }

  # Callbacks
  before_create :generate_invitation_token, if: -> { invitation_token.blank? }
  before_create :set_invited_at, if: -> { invited_at.blank? }

  def pending?
    invited_at.present? && accepted_at.nil?
  end

  def accepted?
    accepted_at.present?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  def role_label
    case role
    when "viewer" then "閲覧者"
    when "editor" then "編集者"
    when "admin" then "管理者"
    else role
    end
  end

  private

  def generate_invitation_token
    self.invitation_token = SecureRandom.urlsafe_base64(24)
  end

  def set_invited_at
    self.invited_at = Time.current
  end

  def cannot_add_owner_as_collaborator
    if recipe.present?
      if user_id.present? && recipe.user_id == user_id
        errors.add(:user, "cannot be added as a collaborator (already the owner)")
      elsif invite_email.present? && recipe.user.present? && invite_email.to_s.downcase.strip == recipe.user.email.to_s.downcase.strip
        errors.add(:invite_email, "cannot be the owner's email")
      end
    end
  end

  def user_or_email_present
    unless user_id.present? || invite_email.present?
      errors.add(:base, "招待先のユーザーまたはメールアドレスを指定してください")
    end
  end
end

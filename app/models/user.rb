class User < ApplicationRecord
  MAX_AVATAR_SIZE = 5.megabytes
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  MAX_AVATAR_SIZE = 5.megabytes
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze

  # MVP: keep profile fields on users for simplicity; extract to Profile later if needed.
  has_one_attached :avatar

  has_many :recipes, dependent: :destroy
  has_many :saved_recipes, dependent: :destroy
  has_many :favorite_recipes, through: :saved_recipes, source: :recipe
  has_many :recipe_collaborations, class_name: "RecipeCollaborator", dependent: :destroy
  has_many :collaborated_recipes, through: :recipe_collaborations, source: :recipe
  has_many :recipe_reports, dependent: :destroy

  before_validation :normalize_username

  validates :display_name, length: { maximum: 30 }
  validates :bio, length: { maximum: 160 }
  validates :username,
            length: { in: 3..20 },
            format: { with: /\A[a-z0-9_]+\z/i },
            uniqueness: { case_sensitive: false },
            allow_nil: true
  validate :avatar_content_type
  validate :avatar_size

  def profile_slug
    username.presence || id.to_s
  end

  private

  def normalize_username
    self.username = username.presence
  end

  def avatar_content_type
    return unless avatar.attached?

    return if AVATAR_CONTENT_TYPES.include?(avatar.content_type)

    errors.add(:avatar, "はPNG/JPEG/WEBP形式の画像を選択してください")
  end

  def avatar_size
    return unless avatar.attached?

    if avatar.blob.byte_size > MAX_AVATAR_SIZE
      errors.add(:avatar, "は5MB以下の画像を選択してください")
    end
  end
end

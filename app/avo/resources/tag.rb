class Avo::Resources::Tag < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  self.title = :display_label

  def fields
    field :id, as: :id
    field :key, as: :text, required: true
    field :label_ja, as: :text, name: "Label (JA)"
    field :position, as: :number
    field :active, as: :boolean
    field :recipes, as: :has_many
  end
end

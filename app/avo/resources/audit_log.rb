class Avo::Resources::AuditLog < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :item_type, as: :text
    field :item_id, as: :number
    field :action, as: :text
    field :whodunnit, as: :number
    field :metadata, as: :code
    field :created_at, as: :date_time
  end
end

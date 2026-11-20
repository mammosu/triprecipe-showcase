class Avo::Resources::EventLog < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :event_type, as: :text
    field :recipe, as: :belongs_to
    field :actor, as: :text
    field :metadata, as: :code
  end
end

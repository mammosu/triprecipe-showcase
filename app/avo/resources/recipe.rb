class Avo::Resources::Recipe < Avo::BaseResource
  self.authorization_policy = AdminPolicy
  self.find_record_method = -> {
    if id.is_a?(Array)
      numeric_ids = id.select { |value| value.to_s.match?(/\A\d+\z/) }.map(&:to_i)
      scope = query.where(slug: id)
      scope = scope.or(query.where(id: numeric_ids)) if numeric_ids.any?
      if query.klass.reflect_on_association(:slug_aliases)
        scope = scope.or(query.joins(:slug_aliases).where(recipe_slugs: { slug: id }))
      end
      scope
    else
      begin
        Recipe.fetch_by_slug!(id)
      rescue ActiveRecord::RecordNotFound
        record = query.find_by(id: id)
        record || raise(ActiveRecord::RecordNotFound, "Couldn't find Recipe with 'id'=#{id}")
      end
    end
  }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :title, as: :text
    field :city, as: :belongs_to
    field :city_display, as: :text, name: "City (manual)"
    field :days_count, as: :number, name: "Days"
    field :public, as: :boolean, name: "Visibility"
    field :cover_image, as: :file, is_image: true
    field :tags, as: :has_many, show_on: :forms
  end
end

module VersionsHelper
  ALLOWED_MODELS = {
    "Recipe" => Recipe,
    "RecipeDay" => RecipeDay,
    "RecipeStep" => RecipeStep
  }.freeze
  RESTORABLE_RECIPE_ATTRS = %w[title description city_display days_count public].freeze

  def version_model_label(item_type)
    ALLOWED_MODELS[item_type]&.model_name&.human || item_type
  end

  def version_attribute_label(item_type, attr)
    klass = ALLOWED_MODELS[item_type]
    klass&.human_attribute_name(attr, default: attr) || attr
  end

  def version_event_label(event)
    case event
    when "update"
      "更新"
    when "create"
      "作成"
    when "destroy"
      "削除"
    else
      event.to_s
    end
  end

  def format_version_value(value)
    return "（空）" if value.nil? || (value.respond_to?(:empty?) && value.empty?)

    if value.is_a?(Time) || value.is_a?(Date) || value.is_a?(DateTime)
      I18n.l(value)
    elsif value.is_a?(Array)
      value.map { |entry| format_version_value(entry) }.join(", ")
    else
      value.is_a?(String) ? truncate(value, length: 120) : value.to_s
    end
  rescue I18n::ArgumentError
    value.to_s
  end

  def restorable_version?(version)
    return false unless version&.item_type == "Recipe"
    return false unless version.event == "update"
    return false unless version.changeset.present?

    version.changeset.slice(*RESTORABLE_RECIPE_ATTRS).present?
  end
end

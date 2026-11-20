module AuditLogsHelper
  def human_action(action)
    case action
    when "create" then "作成"
    when "update" then "更新"
    when "destroy" then "削除"
    when "fork" then "コピー"
    else action
    end
  end

  def format_audit_metadata(log)
    metadata = log.metadata
    return "" if metadata.blank?

    safe_join(
      metadata.map do |field, diff|
        label = human_attribute_label(log.item_type, field)
        render_metadata_field(label, diff)
      end
    )
  end

  private

  def render_metadata_field(label, value)
    if diff_hash?(value)
      content = "#{label}: #{format_scalar(value['old'])} → #{format_scalar(value['new'])}"
      return content_tag(:div, content, class: metadata_line_class(0))
    end

    header = content_tag(:div, "#{label}:", class: metadata_line_class(0))
    body = render_metadata_value(value, indent: 1)
    safe_join([ header, body ].compact)
  end

  def render_metadata_value(value, indent:)
    case value
    when Array
      safe_join(
        value.each_with_index.map do |item, index|
          header = content_tag(:div, "- [#{index + 1}]", class: metadata_line_class(indent))
          nested = render_metadata_value(item, indent: indent + 1)
          safe_join([ header, nested ].compact)
        end
      )
    when Hash
      safe_join(
        value.map do |key, child|
          if diff_hash?(child)
            content = "#{key}: #{format_scalar(child['old'])} → #{format_scalar(child['new'])}"
            content_tag(:div, content, class: metadata_line_class(indent))
          elsif child.is_a?(Hash) || child.is_a?(Array)
            header = content_tag(:div, "#{key}:", class: metadata_line_class(indent))
            nested = render_metadata_value(child, indent: indent + 1)
            safe_join([ header, nested ].compact)
          else
            content_tag(:div, "#{key}: #{format_scalar(child)}", class: metadata_line_class(indent))
          end
        end
      )
    else
      content_tag(:div, format_scalar(value), class: metadata_line_class(indent))
    end
  end

  def diff_hash?(value)
    value.is_a?(Hash) && value.key?("old") && value.key?("new") && value.keys.all? { |k| %w[old new].include?(k) }
  end

  def format_scalar(value)
    return "nil" if value.nil?
    return value.to_s unless value.is_a?(String)

    value
  end

  def metadata_line_class(indent)
    base = "text-xs text-gray-600 font-mono break-words whitespace-pre-wrap"
    indent_class = case indent
    when 0 then nil
    when 1 then "pl-4"
    when 2 then "pl-8"
    when 3 then "pl-12"
    else "pl-12"
    end
    [ base, indent_class ].compact.join(" ")
  end

  def human_attribute_label(item_type, attr)
    klass = item_type.safe_constantize
    return attr unless klass&.respond_to?(:human_attribute_name)

    klass.human_attribute_name(attr, default: attr)
  end

  def human_model_name(item_type)
    klass = item_type.safe_constantize
    return item_type unless klass&.respond_to?(:model_name)

    klass.model_name.human
  end
end

require "pagy/frontend"

module ApplicationHelper
  include Pagy::Frontend
  DEFAULT_META_DESCRIPTION = "TripRecipe is a place to share real trip recipes you can actually follow.".freeze
  DEFAULT_PAGE_TITLE = "TripRecipe".freeze
  DEFAULT_OG_IMAGE_PATH = "/ogp/home.png".freeze

  def default_meta_description
    DEFAULT_META_DESCRIPTION
  end

  def seo_page_title
    raw_title = content_for?(:title) ? strip_tags(content_for(:title)) : nil
    return DEFAULT_PAGE_TITLE if raw_title.blank?

    raw_title.include?(DEFAULT_PAGE_TITLE) ? raw_title : "#{raw_title} | #{DEFAULT_PAGE_TITLE}"
  end

  def seo_meta_description
    raw_description = content_for?(:meta_description) ? content_for(:meta_description) : default_meta_description
    truncate(strip_tags(raw_description), length: 150)
  end

  def seo_canonical_url
    canonical = if content_for?(:canonical_url)
                  content_for(:canonical_url)
    elsif defined?(request) && request.present?
                  request.fullpath
    end

    canonical.present? ? absolute_url_for(canonical) : nil
  end

  def seo_og_image_url
    og_image = content_for?(:og_image) ? content_for(:og_image) : DEFAULT_OG_IMAGE_PATH
    absolute_url_for(og_image) if og_image.present?
  end

  def seo_twitter_card
    content_for?(:twitter_card) ? content_for(:twitter_card) : "summary_large_image"
  end

  def render_og_meta_tags
    tags = []
    tags << tag.meta(property: "og:title", content: seo_page_title)
    tags << tag.meta(property: "og:description", content: seo_meta_description)
    tags << tag.meta(property: "og:url", content: seo_canonical_url) if seo_canonical_url.present?
    tags << tag.meta(property: "og:site_name", content: DEFAULT_PAGE_TITLE)
    tags << tag.meta(property: "og:type", content: content_for?(:og_type) ? content_for(:og_type) : "website")
    og_image = seo_og_image_url
    if og_image.present?
      tags << tag.meta(property: "og:image", content: og_image)
      tags << tag.meta(property: "og:image:width", content: "1200")
      tags << tag.meta(property: "og:image:height", content: "630")
    end

    tags << tag.meta(name: "twitter:card", content: seo_twitter_card)
    tags << tag.meta(name: "twitter:title", content: seo_page_title)
    tags << tag.meta(name: "twitter:description", content: seo_meta_description)
    tags << tag.meta(name: "twitter:image", content: og_image) if og_image.present?

    safe_join(tags)
  end

  def heroicon(name, classes: "", variant: :outline)
    path = Rails.root.join("app/views/shared/icons/heroicons", variant.to_s, "#{name}.svg")
    return "" unless File.exist?(path)

    svg = File.read(path)
    if classes.present?
      svg = svg.sub("<svg ", "<svg class=\"#{ERB::Util.html_escape(classes)}\" ")
    end

    svg.html_safe
  end

  def display_user_identifier(user)
    return "" unless user
    if user.respond_to?(:display_name) && user.display_name.present?
      user.display_name
    else
      mask_email_for_display(user)
    end
  end

  def user_initial(user)
    return "?" unless user
    label = user.respond_to?(:display_name) && user.display_name.present? ? user.display_name : user.email.to_s
    label[0].to_s.upcase
  end

  def safe_return_path(param, fallback:)
    return fallback if param.blank?

    uri = URI.parse(param)
    return fallback unless uri.relative? && uri.scheme.nil? && uri.host.nil?

    path = uri.path.to_s
    return fallback unless path.start_with?("/") && !path.start_with?("//")

    param
  rescue URI::InvalidURIError
    fallback
  end

  private

  def site_base_url
    env_base_url = ENV["APP_BASE_URL"].presence
    return env_base_url if env_base_url.present?

    if defined?(request) && request.present? && request.base_url.present?
      return request.base_url
    end

    default_options = Rails.application.routes.default_url_options
    host = default_options[:host]
    return if host.blank?

    protocol = default_options[:protocol].presence || "https"
    protocol = protocol.delete_suffix("://")
    "#{protocol}://#{host}".chomp("/")
  end

  def absolute_url_for(path)
    return if path.blank?
    return path if path.to_s.start_with?("http://", "https://")

    base = site_base_url
    return path if base.blank?

    base.chomp!("/")
    path = path.to_s
    path = "/#{path}" unless path.start_with?("/")
    base + path
  end

  def mask_email_for_display(user)
    return "" if user.nil?

    email = user.email.to_s
    local, domain = email.split("@", 2)
    return email unless domain && local
    masked_local = if local.length <= 3
                     local[0] + "***"
    else
                     local[0, 3] + "***"
    end
    "#{masked_local}"
  end
end

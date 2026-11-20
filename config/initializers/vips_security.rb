ENV["VIPS_BLOCK_UNTRUSTED"] ||= "1"

begin
  require "vips"

  Vips.block_untrusted(true) if Vips.respond_to?(:block_untrusted)
rescue LoadError
  Rails.logger.warn("ruby-vips is unavailable; Active Storage image variants may fail")
end

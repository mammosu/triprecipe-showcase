# Configure ActionMailer SMTP settings based on MAIL_PROVIDER environment variable.
# Supports: "sendgrid" (default), "mailgun", "test" (sets delivery_method to :test).
# Keep this initializer minimal and avoid application-specific logic.

if Rails.env.test?
  # Ensure tests always use the :test delivery method (avoid SMTP).
  ActionMailer::Base.delivery_method = :test
else
  provider = ENV.fetch("MAIL_PROVIDER", "sendgrid").to_s.downcase

  case provider
  when "mailgun"
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      address: ENV.fetch("MAILGUN_SMTP_SERVER", "smtp.mailgun.org"),
      port: ENV.fetch("MAILGUN_SMTP_PORT", 587).to_i,
      domain: ENV.fetch("MAIL_DOMAIN", "triprecipe.app"),
      user_name: ENV["MAILGUN_SMTP_LOGIN"],
      password: ENV["MAILGUN_SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
    }
  when "sendgrid"
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      address: "smtp.sendgrid.net",
      port: 587,
      domain: ENV.fetch("MAIL_DOMAIN", "triprecipe.app"),
      user_name: "apikey",
      password: ENV["SENDGRID_API_KEY"],
      authentication: :plain,
      enable_starttls_auto: true
    }
  when "test"
    ActionMailer::Base.delivery_method = :test
  else
    # Unknown provider: fallback to SendGrid SMTP for backward compatibility.
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      address: "smtp.sendgrid.net",
      port: 587,
      domain: ENV.fetch("MAIL_DOMAIN", "triprecipe.app"),
      user_name: "apikey",
      password: ENV["SENDGRID_API_KEY"],
      authentication: :plain,
      enable_starttls_auto: true
    }
  end
end

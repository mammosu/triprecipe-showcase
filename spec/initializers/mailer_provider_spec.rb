require "rails_helper"

RSpec.describe "mailer_provider initializer" do
  around do |example|
    # Save originals
    orig_env = {
      "MAIL_PROVIDER" => ENV["MAIL_PROVIDER"],
      "MAILGUN_SMTP_SERVER" => ENV["MAILGUN_SMTP_SERVER"],
      "MAILGUN_SMTP_PORT" => ENV["MAILGUN_SMTP_PORT"],
      "MAILGUN_SMTP_LOGIN" => ENV["MAILGUN_SMTP_LOGIN"],
      "MAILGUN_SMTP_PASSWORD" => ENV["MAILGUN_SMTP_PASSWORD"],
      "SENDGRID_API_KEY" => ENV["SENDGRID_API_KEY"],
      "MAIL_DOMAIN" => ENV["MAIL_DOMAIN"]
    }
    orig_smtp = ActionMailer::Base.smtp_settings.dup rescue nil
    orig_delivery = ActionMailer::Base.delivery_method

    begin
      example.run
    ensure
      # Restore env
      orig_env.each { |k, v| ENV[k] = v }
      ActionMailer::Base.smtp_settings = orig_smtp if orig_smtp
      ActionMailer::Base.delivery_method = orig_delivery
    end
  end

  it "configures Mailgun when MAIL_PROVIDER=mailgun" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    ENV["MAIL_PROVIDER"] = "mailgun"
    ENV["MAILGUN_SMTP_SERVER"] = "smtp.mailgun.org"
    ENV["MAILGUN_SMTP_PORT"] = "2525"
    ENV["MAILGUN_SMTP_LOGIN"] = "login"
    ENV["MAILGUN_SMTP_PASSWORD"] = "pass"
    ENV["MAIL_DOMAIN"] = "example.com"

    load Rails.root.join("config/initializers/mailer_provider.rb")

    expect(ActionMailer::Base.delivery_method).to eq(:smtp)
    expect(ActionMailer::Base.smtp_settings[:address]).to eq("smtp.mailgun.org")
    expect(ActionMailer::Base.smtp_settings[:port]).to eq(2525)
    expect(ActionMailer::Base.smtp_settings[:user_name]).to eq("login")
    expect(ActionMailer::Base.smtp_settings[:password]).to eq("pass")
    expect(ActionMailer::Base.smtp_settings[:domain]).to eq("example.com")
  end

  it "configures SendGrid when MAIL_PROVIDER is not set (default)" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    ENV.delete("MAIL_PROVIDER")
    ENV["SENDGRID_API_KEY"] = "sg_key"

    load Rails.root.join("config/initializers/mailer_provider.rb")

    expect(ActionMailer::Base.delivery_method).to eq(:smtp)
    expect(ActionMailer::Base.smtp_settings[:address]).to eq("smtp.sendgrid.net")
    expect(ActionMailer::Base.smtp_settings[:password]).to eq("sg_key")
  end

  it "falls back to SendGrid for unknown provider" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    ENV["MAIL_PROVIDER"] = "unknown"
    ENV["SENDGRID_API_KEY"] = "sg_key2"

    load Rails.root.join("config/initializers/mailer_provider.rb")

    expect(ActionMailer::Base.delivery_method).to eq(:smtp)
    expect(ActionMailer::Base.smtp_settings[:address]).to eq("smtp.sendgrid.net")
    expect(ActionMailer::Base.smtp_settings[:password]).to eq("sg_key2")
  end

  it "forces test delivery method in test environment" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
    ENV["MAIL_PROVIDER"] = "mailgun"

    load Rails.root.join("config/initializers/mailer_provider.rb")

    expect(ActionMailer::Base.delivery_method).to eq(:test)
  end
end

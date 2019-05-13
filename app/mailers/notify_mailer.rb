class NotifyMailer < GovukNotifyRails::Mailer
  # Require relative statement required as concern not found when loaded from sidekiq on retry
  require_relative 'concerns/notify_template_methods'
  include NotifyTemplateMethods

  def citizen_start_email(app_id, email, application_url, client_name)
    template_name :citizen_start_application
    set_personalisation(application_url: application_url, client_name: client_name, ref_number: app_id)
    mail(to: email)
  end
end

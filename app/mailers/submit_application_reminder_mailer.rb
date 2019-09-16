class SubmitApplicationReminderMailer < GovukNotifyRails::Mailer
  require_relative 'concerns/notify_template_methods'
  include NotifyTemplateMethods

  def notify_provider(application, name, to = support_email_address)
    template_name :reminder_to_submit_an_application
    set_personalisation(
      email: to,
      provider_name: name,
      ref_number: application['application_ref'],
      delegated_functions_date: application['used_delegated_functions_on'],
      deadline_date: application['substantive_application_deadline_on']
    )
    mail to: to
  end
end

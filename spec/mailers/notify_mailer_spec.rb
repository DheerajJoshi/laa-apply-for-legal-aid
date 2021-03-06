require 'rails_helper'

RSpec.describe NotifyMailer, type: :mailer do
  let(:app_id) { SecureRandom.uuid }
  let(:email) { Faker::Internet.safe_email }
  let(:client_name) { Faker::Name.name }
  let(:application_url) { "/applications/#{app_id}/citizen/start" }
  let(:citizen_start_application_template) { Rails.configuration.govuk_notify_templates[:citizen_start_application] }

  it 'uses GovukNotifyMailerJob' do
    expect(described_class.delivery_job).to eq(GovukNotifyMailerJob)
  end

  describe '#citizen_start_email' do
    let(:mail) { described_class.citizen_start_email(app_id, email, application_url, client_name) }

    it 'sends an email to the correct address' do
      expect(mail.to).to eq([email])
    end

    it 'is a govuk_notify delivery' do
      expect(mail.delivery_method).to be_a(GovukNotifyRails::Delivery)
    end

    it 'sets the correct template' do
      expect(mail.govuk_notify_template).to eq(citizen_start_application_template)
    end

    it 'has the right personalisation' do
      expect(mail.govuk_notify_personalisation).to eq(
        application_url: application_url,
        client_name: client_name,
        ref_number: app_id
      )
    end
  end
end

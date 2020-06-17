require 'rails_helper'

RSpec.describe SubmitCitizenFinancialReminderMailer, type: :mailer do
  let(:application) { create :legal_aid_application, :with_applicant, :with_everything }
  let(:email) { Faker::Internet.safe_email }
  let(:provider_name) { Faker::Name.name }
  let(:application_url) { 'http://test.com' }

  describe '#notify_citizen' do
    let(:mail) { described_class.notify_citizen(application.application_ref, email, application_url, application.applicant.full_name) }

    it 'sends an email to the correct address' do
      expect(mail.to).to eq([email])
    end

    it 'is a govuk_notify delivery' do
      expect(mail.delivery_method).to be_a(GovukNotifyRails::Delivery)
    end

    it 'sets the correct template' do
      expect(mail.govuk_notify_template).to eq('e8052551-2afa-4b11-b3e3-578248d9b582')
    end

    it 'has the right personalisation' do
      expect(mail.govuk_notify_personalisation).to eq(
        ref_number: application.application_ref,
        client_name: application.applicant.full_name,
        application_url: application_url
      )
    end
  end
end
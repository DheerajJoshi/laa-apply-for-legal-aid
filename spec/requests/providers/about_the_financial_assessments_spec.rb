require 'rails_helper'

RSpec.describe 'about financial assessments requests', type: :request do
  let(:application) { create(:legal_aid_application, :with_proceeding_types, :with_applicant_and_address) }
  let(:application_id) { application.id }

  describe 'GET /providers/applications/:legal_aid_application_id/about_the_financial_assessment' do
    let(:perform_request) { get "/providers/applications/#{application_id}/about_the_financial_assessment" }

    it_behaves_like 'a provider not authenticated'

    context 'when the provider is authenticated' do
      let(:provider) { create(:provider) }

      before do
        login_as provider
        perform_request
      end

      context 'when the application does not exist' do
        let(:application_id) { SecureRandom.uuid }

        it 'redirects to the applications page with an error' do
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end
      end

      it 'returns success' do
        expect(response).to be_successful
      end

      it 'displays the correct page' do
        expect(unescaped_response_body).to include('About the online financial assessment')
      end
    end
  end

  describe 'POST /providers/applications/:legal_aid_application_id/about_the_financial_assessment/submit' do
    let(:perform_request) { post "/providers/applications/#{application_id}/about_the_financial_assessment/submit" }
    let(:post_request) { post "/providers/applications/#{application_id}/about_the_financial_assessment/submit" }
    let(:mocked_email_service) { instance_double(CitizenEmailService) }

    it_behaves_like 'a provider not authenticated'

    context 'when the provider is authenticated' do
      let(:provider) { create(:provider) }

      before do
        login_as provider
      end

      context 'when the application does not exist' do
        let(:application_id) { SecureRandom.uuid }

        it 'redirects to the applications page without calling the email service' do
          expect(CitizenEmailService).not_to receive(:new)

          post_request

          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end
      end

      context 'when the application exists' do
        before do
          allow(CitizenEmailService).to receive(:new).with(application).and_return(mocked_email_service)
          allow(mocked_email_service).to receive(:send_email)
        end

        context 'but has already been submitted by the provider' do
          let(:application) { create(:legal_aid_application, :with_applicant, :provider_submitted) }

          it 'raises a state transition error' do
            expect { post_request }
              .to raise_error(AASM::InvalidTransition, /Event 'provider_submit' cannot transition from 'provider_submitted/)
          end

          it 'does not send an email to the citizen' do
            expect(CitizenEmailService).not_to receive(:new)

            begin
              post_request
            rescue StandardError
              nil
            end
          end
        end

        it 'changes the application state to "provider_submitted"' do
          expect { post_request }
            .to change { application.reload.state }
            .from('initiated').to('provider_submitted')
        end

        it 'sends an e-mail to the citizen' do
          expect(CitizenEmailService).to receive(:new).with(application).and_return(mocked_email_service)
          expect(mocked_email_service).to receive(:send_email)

          post_request
        end

        it 'display confirmation page after calling the email service' do
          post_request
          expect(response.body).to include(application.application_ref)
        end
      end
    end
  end
end

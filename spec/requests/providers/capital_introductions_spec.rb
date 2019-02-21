require 'rails_helper'

RSpec.describe Providers::CapitalIntroductionsController, type: :request do
  let(:legal_aid_application) { create :legal_aid_application }
  let(:provider) { legal_aid_application.provider }

  describe 'GET /providers/applications/:id/capital_introduction' do
    subject { get providers_legal_aid_application_capital_introduction_path(legal_aid_application) }

    context 'when the provider is not authenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'when the provider is authenticated' do
      before do
        login_as provider
        subject
      end

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Before you continue')
      end

      context 'when the Continue button is pressed' do
        subject { patch providers_legal_aid_application_capital_introduction_path(legal_aid_application) }
        let(:submit_button) { { continue_button: 'Continue' } }

        it 'redirects to next page' do
          subject
          expect(response).to redirect_to(providers_legal_aid_application_own_home_path(legal_aid_application))
        end
      end
    end
  end

  describe 'PATCH /providers/applications/:application_id/capital_introduction' do
    subject { patch providers_legal_aid_application_check_benefit_path(legal_aid_application.id), params: params }

    context 'when the provider is authenticated' do
      before do
        login_as provider
        subject
      end

      context 'Form submitted using Save as draft button' do
        let(:params) { { draft_button: 'Save as draft' } }

        it "redirects provider to provider's applications page" do
          subject
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end

        it 'sets the application as draft' do
          expect(legal_aid_application.reload).to be_draft
        end
      end
    end
  end
end

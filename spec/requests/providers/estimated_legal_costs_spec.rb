require 'rails_helper'

RSpec.describe Providers::EstimatedLegalCostsController, type: :request do
  let(:legal_aid_application) { create :legal_aid_application, :with_applicant }
  let(:provider) { legal_aid_application.provider }
  let!(:estimated_legal_cost_as_text) { '250,000.00' }

  describe 'GET /providers/applications/:id/estimated_legal_costs' do
    subject { get providers_legal_aid_application_estimated_legal_costs_path(legal_aid_application) }

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
      end
    end
  end

  describe 'PATCH #/providers/applications/:legal_aid_application_id/estimated_legal_costs' do
    let(:params) do
      {
        merits_assessment: {
          estimated_legal_cost: estimated_legal_cost_as_text
        }
      }
    end

    subject { patch providers_legal_aid_application_estimated_legal_costs_path(legal_aid_application), params: params.merge(submit_button) }

    context 'when the provider is authenticated' do
      before do
        login_as legal_aid_application.provider
      end

      context 'Submitted with Continue button' do
        let(:submit_button) do
          {
            continue_button: 'Continue'
          }
        end

        let!(:estimated_legal_cost) { 250_000 }

        it 'does NOT create an new application record' do
          expect { subject }.not_to change { LegalAidApplication.count }
        end

        it 'redirects to the next page' do
          subject
          expect(response).to redirect_to(providers_legal_aid_application_success_prospects_path(legal_aid_application))
        end

        it 'update legal_aid_application.merits_assessment record' do
          expect(legal_aid_application.merits_assessment).to eq nil
          subject
          expect(legal_aid_application.reload.merits_assessment.estimated_legal_cost).to eq estimated_legal_cost
        end

        context 'with an invalid param' do
          context 'value is not entered' do
            let(:params) { { merits_assessment: { estimated_legal_cost: '' } } }
            it 're-renders the form with the validation errors' do
              subject
              expect(unescaped_response_body).to include('There is a problem')
              expect(unescaped_response_body).to include('Enter the estimated legal costs of doing the work')
            end
          end

          context 'non number entered' do
            let(:params) { { merits_assessment: { estimated_legal_cost: 'abc' } } }
            it 're-renders the form with the validation errors' do
              subject
              expect(unescaped_response_body).to include('There is a problem')
              expect(unescaped_response_body).to include('Estimated cost must be an amount of money, like 25,000')
            end
          end
        end
      end

      context 'Submitted with Save as draft button' do
        let(:submit_button) do
          {
            draft_button: 'Save as draft'
          }
        end

        let!(:estimated_legal_cost) { 250_000 }

        it 'updates the estimated_legal_cost amount' do
          expect(legal_aid_application.merits_assessment).to eq nil
          subject
          expect(legal_aid_application.reload.merits_assessment.estimated_legal_cost).to eq estimated_legal_cost
        end

        it "redirects provider to provider's applications page" do
          subject
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end

        it 'sets the application as draft' do
          expect { subject }.to change { legal_aid_application.reload.draft? }.from(false).to(true)
        end

        context 'with an invalid param' do
          context 'value is not entered' do
            let(:params) { { merits_assessment: { estimated_legal_cost: '' } } }
            it "redirects provider to provider's applications page" do
              subject
              expect(response).to redirect_to(providers_legal_aid_applications_path)
            end
          end

          context 'non number entered' do
            let(:params) { { merits_assessment: { estimated_legal_cost: 'abc' } } }
            it 're-renders the form with the validation errors' do
              subject
              expect(unescaped_response_body).to include('There is a problem')
              expect(unescaped_response_body).to include('Estimated cost must be an amount of money, like 25,000')
            end
          end
        end
      end
    end
  end
end

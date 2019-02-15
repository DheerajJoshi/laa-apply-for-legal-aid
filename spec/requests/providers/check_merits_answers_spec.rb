require 'rails_helper'

RSpec.describe 'check merits answers requests', type: :request do
  include ActionView::Helpers::NumberHelper

  describe 'GET /providers/applications/:id/check_merits_answers' do
    let(:application) do
      create :legal_aid_application,
             :with_everything,
             :means_completed
    end

    subject { get "/providers/applications/#{application.id}/check_merits_answers" }

    context 'unauthenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'logged in as an authenticated provider' do
      before do
        login_as create(:provider)
        subject
      end

      it 'displays the correct page' do
        expect(unescaped_response_body).to include('Check your answers')
      end

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end

      it 'displays the correct questions' do
        expect(response.body).to include(I18n.translate('providers.check_merits_answers.show.items.client_received_legal_help'))
        expect(response.body).to include(I18n.translate('providers.check_merits_answers.show.items.proceedings_currently_before_court'))
        expect(response.body).to include(I18n.translate('providers.check_merits_answers.show.items.statement_of_case'))
        expect(response.body).to include(I18n.translate('providers.check_merits_answers.show.items.estimated_legal_costs'))
        expect(response.body).to include(I18n.translate('providers.check_merits_answers.show.items.prospects_of_success'))
        expect(response.body).to include(I18n.translate('providers.check_merits_answers.show.items.client_declaration'))
      end

      it 'displays the correct URLs for changing values' do
        expect(response.body).to have_change_link(:client_received_legal_help, providers_legal_aid_application_client_received_legal_help_path(application))
        expect(response.body).to have_change_link(:proceedings_currently_before_court, providers_legal_aid_application_proceedings_before_the_court_path(application))
        expect(response.body).to have_change_link(:statement_of_case, providers_legal_aid_application_statement_of_case_path(application))
        expect(response.body).to have_change_link(:estimated_legal_costs, providers_legal_aid_application_estimated_legal_costs_path(application))
        expect(response.body).to have_change_link(:prospects_of_success, providers_legal_aid_application_success_prospects_path(application))
        expect(response.body).to have_change_link(:client_declaration, providers_legal_aid_application_merits_declaration_path(application))
      end

      context 'client has not received legal help' do
        it 'displays whether the client has received legal help, with supplementary text' do
          expect(response.body).to include('No')
          expect(response.body).to include(application.merits_assessment.application_purpose)
        end
      end

      context 'proceedings are before the court' do
        it 'displays whether proceedings are currently before the court, with supplementary text' do
          expect(response.body).to include 'Yes'
          expect(response.body).to include(application.merits_assessment.details_of_proceedings_before_the_court)
        end
      end

      it 'displays the statement of case' do
        expect(response.body).to include(application.statement_of_case.statement)
      end

      it 'displays the estimated legal costs' do
        expect(response.body).to include(number_to_currency(application.merits_assessment.estimated_legal_cost, unit: '£'))
      end

      context 'prospects of success has supplementary text' do
        it 'displays the prospects of success and details' do
          expect(response.body).to include(I18n.translate("shared.forms.success_prospect.success_prospect_item.#{application.merits_assessment.success_prospect}"))
          expect(response.body).to include(application.merits_assessment.success_prospect_details)
        end
      end

      it 'displays the client declaration' do
        expect(unescaped_response_body).to include(I18n.translate('providers.check_merits_answers.show.items.client_declaration_answer'))
      end

      it 'should change the state to "checking_merits_answers"' do
        expect(application.reload.checking_merits_answers?).to be_truthy
      end

      it 'has a back link to the client declaration page' do
        expect(response.body).to have_back_link(reset_providers_legal_aid_application_check_merits_answers_path)
      end
    end
  end

  describe 'PATCH /providers/applications/:id/check_merits_answers/continue' do
    let(:application) do
      create :legal_aid_application,
             :with_everything,
             :checking_merits_answers
    end
    let(:params) { {} }
    subject do
      patch "/providers/applications/#{application.id}/check_merits_answers/continue", params: params
    end

    context 'logged in as an authenticated provider' do
      before do
        login_as create(:provider)
        subject
      end

      it 'returns success' do
        expect(response).to be_successful
      end

      it 'transitions to merits_completed state' do
        expect(application.reload.merits_completed?).to be true
      end

      context 'Form submitted using Save as draft button' do
        let(:params) { { draft_button: 'Save as draft' } }

        it "redirects provider to provider's applications page" do
          subject
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end

        it 'sets the application as draft' do
          expect(application.reload).to be_draft
        end
      end
    end

    context 'unauthenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end
  end

  describe 'PATCH "/providers/applications/:id/check_merits_answers/reset' do
    let(:application) do
      create :legal_aid_application,
             :with_everything,
             :checking_merits_answers
    end

    subject { patch "/providers/applications/#{application.id}/check_merits_answers/reset" }

    context 'unauthenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'logged in as an authenticated provider' do
      before do
        login_as create(:provider)
        get providers_legal_aid_application_merits_declaration_path(application)
        get providers_legal_aid_application_check_merits_answers_path(application)
        subject
      end

      it 'transitions to means_completed state' do
        expect(application.reload.means_completed?).to be true
      end

      describe 'redirection' do
        it 'redirects to client declaration page' do
          expect(response).to redirect_to providers_legal_aid_application_merits_declaration_path(application, back: true)
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe Providers::CapitalIncomeAssessmentResultsController, type: :request do
  include ActionView::Helpers::NumberHelper

  describe 'GET  /providers/applications/:legal_aid_application_id/capital_income_assessment_result' do
    # let(:cfe_result) { create :cfe_v2_result }
    let(:legal_aid_application) { cfe_result.legal_aid_application }
    let(:applicant_name) { legal_aid_application.applicant_full_name }
    let(:locale_scope) { 'providers.capital_income_assessment_results' }

    let(:login_provider) { login_as legal_aid_application.provider }
    let(:before_tasks) do
      Setting.setting.update!(manually_review_all_cases: false)
      login_provider
      subject
    end

    subject { get providers_legal_aid_application_capital_income_assessment_result_path(legal_aid_application) }

    before { before_tasks }

    context 'no restrictions' do
      context 'eligible' do
        let!(:cfe_result) { create :cfe_v2_result, :eligible }
        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays the correct result' do
          expect(unescaped_response_body).to include(I18n.t('eligible.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when not eligible' do
        let!(:cfe_result) { create :cfe_v2_result, :not_eligible }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays the correct result' do
          expect(unescaped_response_body).to include(I18n.t('not_eligible.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when capital contribution required' do
        let(:cfe_result) { create :cfe_v2_result, :with_capital_contribution_required }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays the correct result' do
          expect(unescaped_response_body).to include(I18n.t('capital_contribution_required.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when income contribution required' do
        let(:cfe_result) { create :cfe_v2_result, :with_income_contribution_required }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays the correct result' do
          expect(unescaped_response_body).to include(I18n.t('income_contribution_required.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when both income and capital contribution required' do
        let(:cfe_result) { create :cfe_v2_result, :with_capital_and_income_contributions_required }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays the correct result' do
          expect(unescaped_response_body).to include(I18n.t('capital_and_income_contribution_required.heading', name: applicant_name, scope: locale_scope))
          expect(unescaped_response_body).to include("#{number_to_currency(cfe_result.income_contribution)} from their disposable income")
          expect(unescaped_response_body).to include("#{number_to_currency(cfe_result.capital_contribution)} from their disposable capital")
        end
      end
    end

    context 'with restrictions' do
      let(:before_tasks) do
        Setting.setting.update!(manually_review_all_cases: false)
        create :applicant, legal_aid_application: legal_aid_application, first_name: 'Stepriponikas', last_name: 'Bonstart'
        legal_aid_application.update has_restrictions: true, restrictions_details: 'Blah blah'
        login_provider
        subject
      end

      context 'eligible' do
        let!(:cfe_result) { create :cfe_v2_result, :eligible }
        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays the correct result' do
          expect(unescaped_response_body).to include(I18n.t('eligible.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when capital contribution required' do
        let(:cfe_result) { create :cfe_v2_result, :with_capital_contribution_required }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays manual check required' do
          expect(unescaped_response_body).to include(I18n.t('manual_check_required.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when income contribution required' do
        let(:cfe_result) { create :cfe_v2_result, :with_income_contribution_required }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays manual check required' do
          expect(unescaped_response_body).to include(I18n.t('manual_check_required.heading', name: applicant_name, scope: locale_scope))
        end
      end

      context 'when both income and capital contribution required' do
        let(:cfe_result) { create :cfe_v2_result, :with_capital_and_income_contributions_required }

        it 'returns http success' do
          expect(response).to have_http_status(:ok)
        end

        it 'displays manual check required' do
          expect(unescaped_response_body).to include(I18n.t('manual_check_required.heading', name: applicant_name, scope: locale_scope))
        end
      end
    end

    context 'unauthenticated' do
      let(:before_tasks) { subject }
      let!(:cfe_result) { create :cfe_v2_result, :eligible }
      it_behaves_like 'a provider not authenticated'
    end

    context 'unknown result' do
      let(:cfe_result) { create :cfe_v2_result, result: {}.to_json }
      let(:before_tasks) do
        login_provider
      end

      it 'raises error' do
        expect { subject }.to raise_error(/Unknown capital_assessment_result/)
      end
    end
  end
end

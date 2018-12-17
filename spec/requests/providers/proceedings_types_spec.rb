require 'rails_helper'

RSpec.describe 'providers legal aid application proceedings type requests', type: :request do
  let(:legal_aid_application) { create :legal_aid_application }

  describe 'GET /providers/applications/:legal_aid_application_id/proceedings_type' do
    let(:perform_request) { get providers_legal_aid_application_proceedings_type_path(legal_aid_application) }

    it_behaves_like 'a provider not authenticated'

    context 'when the provider is authenticated' do
      let(:provider) { create(:provider) }

      before do
        login_as provider
        perform_request
      end

      it 'returns http success' do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'PATCH /providers/applications/:legal_aid_application_id/proceedings_type' do
    let(:code) { 'PR0001' }
    let!(:proceeding_type) { create(:proceeding_type, code: code) }
    let(:params) { { proceeding_type: code } }
    let(:perform_request) do
      patch(
        providers_legal_aid_application_proceedings_type_path(legal_aid_application),
        params: params
      )
    end

    context 'when the provider is authenticated' do
      let(:provider) { create(:provider) }

      before do
        login_as provider
        perform_request
      end

      it 'redirects successfully to the next submission step' do
        perform_request
        expect(response).to redirect_to(providers_legal_aid_application_applicant_path(legal_aid_application))
      end

      it 'associates proceeding type with legal aid application' do
        expect(legal_aid_application.reload.proceeding_types).to include(proceeding_type)
      end

      context 'when the params are not valid' do
        let(:params) { { proceeding_type: 'random-code' } }

        it 're-renders the proceeding type selection page' do
          expect(unescaped_response_body).to include('What does your client want legal aid for?')
        end

        it 'renders show' do
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end

require 'rails_helper'

RSpec.describe 'address selections requests', type: :request do
  let(:legal_aid_application) { create(:legal_aid_application, :with_applicant) }
  let(:applicant) { legal_aid_application.applicant }
  let(:provider) { legal_aid_application.provider }

  describe 'GET /providers/applications/:legal_aid_application_id/address_selections/edit' do
    subject { get providers_legal_aid_application_address_selection_path(legal_aid_application) }

    context 'when the provider is not authenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'when the provider is authenticated' do
      before do
        login_as provider
      end

      context 'a postcode have been entered before', :vcr do
        let(:postcode) { 'DA7 4NG' }
        let!(:address) { create :address, postcode: postcode, applicant: applicant }

        it 'performs an address lookup with the provided postcode' do
          expect(AddressLookupService)
            .to receive(:call).with(address.postcode).and_call_original

          subject
        end

        it 'renders the address selection page' do
          subject

          expect(response).to be_successful
          expect(unescaped_response_body).to match('Select an address')
          expect(unescaped_response_body).to match('[1-9]{1}[0-9]? addresses found')
        end

        context 'but the lookup does not return any valid results' do
          let(:postcode) { 'SW1H 9AJ' } # NOTE: test account does not return any results for this postcode
          let(:form_heading) { "Enter your client's correspondence address" }
          let(:error_message) { 'We could not find any addresses for that postcode. Enter the address manually.' }

          it 'renders the manual address selection page' do
            subject

            expect(response).to be_successful
            expect(unescaped_response_body).to match(form_heading)
            expect(unescaped_response_body).to match(error_message)
          end
        end
      end

      context 'no postcode have been entered yet' do
        before do
          get providers_legal_aid_application_address_lookup_path(legal_aid_application)
        end

        it 'redirects to the postcode entering page' do
          subject
          expect(response).to redirect_to(providers_legal_aid_application_address_lookup_path(back: true))
        end
      end
    end
  end

  describe 'PATCH /providers/applications/:legal_aid_application_id/address_selections' do
    let(:address_list) do
      [
        { lookup_id: '11', address_line_one: '1', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '12', address_line_one: '2', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '13', address_line_one: '3', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '14', address_line_one: '4', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '15', address_line_one: '5', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '16', address_line_one: '6', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '17', address_line_one: '7', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '18', address_line_one: '8', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '19', address_line_one: '9', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '20', address_line_one: '10', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' },
        { lookup_id: '22', address_line_one: '12', address_line_two: 'LONSDALE ROAD', city: 'BEXLEYHEATH', postcode: 'DA7 4NG' }
      ]
    end
    let(:postcode) { 'DA7 4NG' }
    let(:selected_address) { address_list.sample }
    let(:lookup_id) { selected_address[:lookup_id] }
    let(:normalized_postcode) { 'DA74NG' }
    let(:submit_button) { { continue_button: 'Continue' } }
    let(:params) do
      {
        address_selection: {
          list: address_list.map(&:to_json),
          postcode: postcode,
          lookup_id: lookup_id
        }
      }.merge(submit_button)
    end

    subject { patch providers_legal_aid_application_address_selection_path(legal_aid_application), params: params }

    context 'when the provider is not authenticated' do
      before { subject }
      it_behaves_like 'a provider not authenticated'
    end

    context 'when the provider is authenticated' do
      before do
        login_as provider
      end

      context 'when no address was selected from the list' do
        let(:lookup_id) { '' }

        it 'does not create a new address record' do
          expect { subject }.not_to change { Address.count }
        end

        it 'renders the address selection page' do
          subject

          expect(response).to be_successful
          expect(unescaped_response_body).to match('Select an address from the list')
          expect(unescaped_response_body).to match('Select an address')
          expect(unescaped_response_body).to match('[1-9]{1}[0-9]? addresses found')
        end
      end

      it 'creates a new address record associated with the applicant' do
        expect { subject }.to change { applicant.reload.addresses.count }.by(1)
        expect(applicant.address.address_line_one).to eq(selected_address[:address_line_one])
        expect(applicant.address.lookup_id).to eq(lookup_id)
      end

      it 'redirects to next submission step' do
        subject

        expect(response).to redirect_to(providers_legal_aid_application_proceedings_types_path)
      end

      it 'records that the lookup service was used' do
        subject
        expect(applicant.address.lookup_used).to eq(true)
      end

      context 'when an address already exists' do
        before { create :address, applicant: applicant }

        it 'does not create a new address record' do
          expect { subject }.to_not change { applicant.addresses.count }
        end

        it 'updates the current address' do
          subject
          expect(applicant.address.address_line_one).to eq(selected_address[:address_line_one])
          expect(applicant.address.lookup_id).to eq(lookup_id)
        end
      end

      context 'Form submitted using Save as draft button' do
        let(:submit_button) { { draft_button: 'Save as draft' } }

        it "redirects provider to provider's applications page" do
          subject
          expect(response).to redirect_to(providers_legal_aid_applications_path)
        end

        it 'sets the application as draft' do
          expect { subject }.to change { legal_aid_application.reload.draft? }.from(false).to(true)
        end
      end
    end
  end
end

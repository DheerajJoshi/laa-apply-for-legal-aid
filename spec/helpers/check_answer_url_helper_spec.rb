require 'rails_helper'

RSpec.describe CheckAnswerUrlHelper, type: :helper do
  let(:application) { build :legal_aid_application, id: 'bf07c530-718a-4537-b9e1-c04ad956cc71' }

  describe '#check_answer_url_for' do
    context 'provider' do
      it 'returns the correct path for own_home' do
        url = check_answer_url_for(:provider, :own_home, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/own_home'
      end

      it 'returns the correct path for property_value' do
        url = check_answer_url_for(:provider, :property_value, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/property_value#property_value'
      end

      it 'returns the correct path for outstanding mortgage' do
        url = check_answer_url_for(:provider, :outstanding_mortgage, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/outstanding_mortgage#outstanding_mortgage_amount'
      end

      it 'returns the correct path for shared_ownership' do
        url = check_answer_url_for(:provider, :shared_ownership, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/shared_ownership'
      end

      it 'returns the correct path for percentage_home' do
        url = check_answer_url_for(:provider, :percentage_home, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/percentage_home#percentage_home'
      end

      it 'returns the correct path for savings_and_investments' do
        url = check_answer_url_for(:provider, :savings_and_investments, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/savings_and_investment'
      end

      it 'returns the correct path for other_assets' do
        url = check_answer_url_for(:provider, :other_assets, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/other_assets'
      end

      it 'returns the correct path for restrictions' do
        url = check_answer_url_for(:provider, :restrictions, application)
        expect(url).to eq '/providers/applications/bf07c530-718a-4537-b9e1-c04ad956cc71/restrictions'
      end
    end

    context 'citizen' do
      it 'returns the correct path for own_home' do
        url = check_answer_url_for(:citizen, :own_home)
        expect(url).to eq '/citizens/own_home'
      end

      it 'returns the correct path for property_value' do
        url = check_answer_url_for(:citizen, :property_value)
        expect(url).to eq '/citizens/property_value#property_value'
      end

      it 'returns the correct path for outstanding_mortgage' do
        url = check_answer_url_for(:citizen, :outstanding_mortgage)
        expect(url).to eq '/citizens/outstanding_mortgage#outstanding_mortgage_amount'
      end

      it 'returns the correct path for shared_ownership' do
        url = check_answer_url_for(:citizen, :shared_ownership)
        expect(url).to eq '/citizens/shared_ownership'
      end

      it 'returns the correct path for percentage_home' do
        url = check_answer_url_for(:citizen, :percentage_home)
        expect(url).to eq '/citizens/percentage_home#percentage_home'
      end

      it 'returns the correct path for savings_and_investments' do
        url = check_answer_url_for(:citizen, :savings_and_investments)
        expect(url).to eq '/citizens/savings_and_investment'
      end

      it 'returns the correct path for other_assets' do
        url = check_answer_url_for(:citizen, :other_assets)
        expect(url).to eq '/citizens/other_assets'
      end

      it 'returns the correct path for restrictions' do
        url = check_answer_url_for(:citizen, :restrictions)
        expect(url).to eq '/citizens/restrictions'
      end
    end

    context 'error raising' do
      context 'invalid user type' do
        it 'raises' do
          expect {
            check_answer_url_for(:employee, :own_home)
          }.to raise_error ArgumentError, 'Wrong user type passed to #check_answer_url_for'
        end
      end

      context 'provider' do
        context 'invalid field name' do
          it 'raises' do
            expect {
              check_answer_url_for(:provider, :holiday_let, application)
            }.to raise_error ArgumentError, 'Invalid field name for #check_answer_url_for: holiday_let'
          end
        end
      end

      context 'citizen' do
        context 'invalid field name' do
          it 'raises' do
            expect {
              check_answer_url_for(:citizen, :granny_flat)
            }.to raise_error ArgumentError, 'Invalid field name for #check_answer_url_for: granny_flat'
          end
        end
      end
    end
  end
end
require 'rails_helper'

RSpec.describe SaveApplicantMeansAnswers do
  let(:application) { create :legal_aid_application, :with_everything }
  let(:savings_amount) { application.savings_amount }
  let(:other_assets_declaration) { application.other_assets_declaration }
  let(:bank_provider) { create :bank_provider, applicant: application.applicant }
  let(:bank_account) { create :bank_account, bank_provider: bank_provider }
  let!(:bank_transaction_not_selected) { create :bank_transaction, bank_account: bank_account, transaction_type: nil }
  let!(:bank_transaction_selected) { create :bank_transaction, bank_account: bank_account, transaction_type: (create :transaction_type) }
  let!(:bank_transaction_selected_2) { create :bank_transaction, bank_account: bank_account, transaction_type: (create :transaction_type) }
  let(:selected_transactions) { application.bank_transactions.where.not(transaction_type: nil).compact }

  before do
    Restriction.populate
    application.set_transaction_period
    application.restrictions = Restriction.all.sample(Faker::Number.between(1, Restriction.count - 1))
  end

  describe '#call' do
    subject { described_class.call(application) }

    it 'copies the attributes of the application' do
      expect { subject }.to change { application.reload.applicant_means_answers }.from(nil)
      application.reload
      application.attributes.except('applicant_means_answers').each do |key, value|
        got = application.applicant_means_answers[key].to_s
        expected = value.to_s
        if value.is_a?(Time)
          got = got.to_time.to_i
          expected = value.to_i
        end
        expect(got).to eq(expected), "Attr #{key}: expected #{expected}, got #{got}"
      end
    end

    it 'copies the attributes of the savings_amount object' do
      subject
      savings_amount.attributes.each do |key, value|
        got = application.applicant_means_answers['savings_amount'][key].to_s
        expected = value.to_s
        if value.is_a?(Time)
          got = got.to_time.to_i
          expected = value.to_i
        end
        expect(got).to eq(expected), "Attr #{key}: expected #{expected}, got #{got}"
      end
    end

    it 'copies the attributes of the other_assets_declaration object' do
      subject
      other_assets_declaration.attributes.each do |key, value|
        got = application.applicant_means_answers['other_assets_declaration'][key].to_s
        expected = value.to_s
        if value.is_a?(Time)
          got = got.to_time.to_i
          expected = value.to_i
        end
        expect(got).to eq(expected), "Attr #{key}: expected #{expected}, got #{got}"
      end
    end

    it 'copies the restrictions of the application' do
      subject
      restrictions = application.applicant_means_answers['restrictions'].pluck('name')
      expected_restrictions = application.restrictions.pluck(:name)
      expect(restrictions).to match_array(expected_restrictions)
    end

    it 'copies the bank transactions' do
      subject
      expect(application.applicant_means_answers['bank_transactions'].count).to eq(selected_transactions.count)
      selected_transactions.each do |bank_transaction|
        copied_transaction = application.applicant_means_answers['bank_transactions'].find do |transaction|
          transaction['id'] == bank_transaction.id
        end
        bank_transaction.attributes.each do |key, value|
          got = copied_transaction[key].to_s
          expected = value.to_s
          if value.is_a?(Time)
            got = got.to_time.to_i
            expected = value.to_i
          end
          expect(got).to eq(expected), "Attr #{key}: expected #{expected}, got #{got}"
        end
      end
    end

    context 'if no transactions have been selected' do
      let!(:bank_transaction_selected) { nil }
      let!(:bank_transaction_selected_2) { nil }

      it 'copies the application without any bank transactions' do
        expect { subject }.to change { application.reload.applicant_means_answers }.from(nil)
        expect(application.applicant_means_answers['id']).to eq(application.id)
        expect(application.applicant_means_answers['bank_transactions']).to eq([])
      end
    end
  end
end
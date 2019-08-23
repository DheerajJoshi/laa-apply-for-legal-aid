require 'rails_helper'

module CCMS
  RSpec.describe Submission do
    let(:other_party_1) { create :opponent, :child }

    let(:other_party_2)  { create :opponent, :ex_spouse }

    let(:bank_account) do
      double BankAccount,
             bank_provider: bank_provider,
             balance: 100.0,
             account_number: 12_345_678,
             holders: 'ClientSole',
             account_type_label: 'Bank Current',
             display_name: 'the bank account1',
             has_tax_credits?: false,
             has_wages?: true,
             has_benefits?: true
    end

    let(:bank_provider) do
      double BankProvider, name: 'Mock bank'
    end

    let(:vehicle) do
      double Vehicle,
             purchased_on: Date.new(2015, 12, 1),
             used_regularly?: true,
             estimated_value: 5_000.0,
             payment_remaining: 0.0
    end

    let(:wage_slip) do
      double 'WageSlip',
             ni_deducted: 100,
             gross_pay: 1000,
             paye_deducted: 300,
             pay_period: Date.new(2019, 3, 29),
             description: ':EMPLOYMENT_CLIENT_001:CLI_NON_HM_WAGE_SLIP_001'
    end

    let(:provider) do
      double 'Provider',
             username: 'user1',
             firm_id: 22_381,
             selected_office_id: 81_693,
             user_login_id: 2_016_472,
             supervisor_contact_id: 3_982_723,
             fee_earner_contact_id: 34_419,
             marked_for_destruction?: false
    end

    before do
      @statement_of_case = create :statement_of_case, :with_attached_files
      PdfConverter.call(PdfFile.find_or_create_by(original_file_id: @statement_of_case.original_files.first.id).id)
      allow_any_instance_of(LegalAidApplication).to receive(:opponents).and_return([other_party_2, other_party_1])
      allow_any_instance_of(LegalAidApplication).to receive(:vehicle).and_return(vehicle)
      allow_any_instance_of(LegalAidApplication).to receive(:wage_slips).and_return([wage_slip])
      allow_any_instance_of(LegalAidApplication).to receive(:opponent_other_parties).and_return([other_party_2, other_party_1])
      allow_any_instance_of(LegalAidApplication).to receive(:provider).and_return(provider)
      allow_any_instance_of(Applicant).to receive(:bank_accounts).and_return([bank_account])
    end

    before(:all) do
      VCR.configure { |c| c.ignore_hosts 'sitsoa10.laadev.co.uk' }
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    context 'delegated functions case' do
      before do
        @legal_aid_application = create :legal_aid_application, :with_applicant_and_address, :with_proceeding_types, :with_delegated_functions, :with_delegated_functions_scope_limitation, :with_other_assets_declaration, :with_savings_amount, :with_respondent, statement_of_case: @statement_of_case
        @submission = create :submission, legal_aid_application: @legal_aid_application
      end

      describe 'generate case payload only' do
        before do
          @submission.aasm_state = 'applicant_ref_obtained'
        end

        it 'generates the delegated functions CaseAdd payload' do
          # stub ccms case reference as we're not going through the whole path so it won't be generated
          allow_any_instance_of(CCMS::Submission).to receive(:case_ccms_reference).and_return('300000333864')
          @submission.process!(no_call: true, case_type: 'delegated_functions')
        end
      end

      describe 'complete sequence' do
        it 'runs one thing after another' do
          puts "\nCreating delegated functions case"
          run_everything
        end
      end
    end

    context 'substantive case' do
      before do
        @legal_aid_application = create :legal_aid_application, :with_applicant_and_address, :with_proceeding_types, :with_substantive_scope_limitation, :with_other_assets_declaration, :with_savings_amount, :with_respondent, statement_of_case: @statement_of_case
        @submission = create :submission, legal_aid_application: @legal_aid_application
      end

      describe 'generate case payload only' do
        before do
          @submission.aasm_state = 'applicant_ref_obtained'
        end

        it 'generates the substantive CaseAdd payload' do
          # stub ccms case reference as we're not going through the whole path so it won't be generated
          allow_any_instance_of(CCMS::Submission).to receive(:case_ccms_reference).and_return('300000333864')
          @submission.process!(no_call: true, case_type: 'substantive')
        end
      end

      describe 'complete sequence' do
        it 'runs one thing after another' do
          puts "\nCreating substantive case"
          run_everything
        end
      end
    end

    def history
      SubmissionHistory.where(submission_id: @submission.id).order(created_at: :desc).first
    end

    def check_initial_state
      print 'checking initial state.... '
      expect(@submission.aasm_state).to eq 'initialised'
      puts "'initialised'".green
    end

    def request_case_id
      print 'Getting case id... '
      @submission.process!
      expect(@submission.case_ccms_reference).not_to be_nil
      expect(@submission.aasm_state).to eq 'case_ref_obtained'
      expect(history.from_state).to eq 'initialised'
      expect(history.to_state).to eq 'case_ref_obtained'
      expect(history.success).to be true
      puts @submission.case_ccms_reference.green
    end

    def create_an_applicant
      print 'Applicant submitted... '
      expect {
        @submission.process!
      }.not_to change{ @submission.case_ccms_reference }
      expect(@submission.applicant_add_transaction_id).not_to be_nil
      expect(@submission.aasm_state).to eq 'applicant_submitted'
      history.reload
      expect(history.from_state).to eq 'case_ref_obtained'
      expect(history.to_state).to eq 'applicant_submitted'
      expect(history.success).to be true
      expect(history.details).to be_nil
      puts 'done'.green
    end

    def poll_applicant_creation
      print 'Polling applicant creation result... '
      expect { @submission.process! }.to change { @submission.applicant_poll_count }.by(1) while @submission.applicant_ccms_reference.nil?

      expect(@submission.applicant_ccms_reference).not_to be_nil
      expect(@submission.aasm_state).to eq 'applicant_ref_obtained'
      expect(history.from_state).to eq 'applicant_submitted'
      expect(history.to_state).to eq 'applicant_ref_obtained'
      expect(history.success).to be true
      expect(history.details).to be_nil
      puts "Applicant reference #{@submission.applicant_ccms_reference} in #{@submission.applicant_poll_count} attempts.".green
    end

    def create_case
      print 'Submitting case... '
      @submission.process!
      expect(@submission.aasm_state).to eq 'case_submitted'
      expect(history.from_state).to eq 'applicant_ref_obtained'
      expect(history.to_state).to eq 'case_submitted'
      expect(history.success).to be true
      expect(history.details).to be_nil
      puts 'done'.green
    end

    def poll_case_creation_result
      poll_count = 0
      print 'Polling for case creation result'
      while @submission.aasm_state != 'case_created'
        print '...'
        $stdout.flush
        poll_count += 1
        sleep(5)
        @submission.process!
      end

      puts " case created in #{poll_count} attempts".green
      expect(@submission.case_poll_count).to eq poll_count
      expect(@submission.applicant_ccms_reference).not_to be_nil
      expect(@submission.aasm_state).to eq 'case_created'
      expect(history.from_state).to eq 'case_submitted'
      expect(history.to_state).to eq 'case_created'
      expect(history.success).to be true
      expect(history.details).to be_nil
    end

    def request_document_ids
      print 'Requesting document IDs... '
      @submission.process!
      expect(@submission.documents).to_not be_empty
      expect(@submission.documents.values[0]).to eq :id_obtained
      expect(@submission.aasm_state).to eq 'document_ids_obtained'
      expect(history.from_state).to eq 'case_created'
      expect(history.to_state).to eq 'document_ids_obtained'
      expect(history.success).to be true
      expect(history.details).to be_nil
      puts @submission.documents.to_s.green
    end

    def upload_documents
      print 'Uploading documents... '
      @submission.process!
      expect(@submission.documents.values[0]).to eq :uploaded
      expect(@submission.aasm_state).to eq 'completed'
      expect(history.from_state).to eq 'document_ids_obtained'
      expect(history.to_state).to eq 'completed'
      expect(history.success).to be true
      expect(history.details).to be_nil
      puts @submission.documents.to_s.green
    end

    def run_everything
      check_initial_state
      request_case_id
      create_an_applicant
      poll_applicant_creation
      create_case
      poll_case_creation_result
      request_document_ids
      upload_documents
    end
  end
end

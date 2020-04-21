class StateBenefitAnalyserService
  def self.call(legal_aid_application)
    new(legal_aid_application).call
  end

  def initialize(legal_aid_application)
    @legal_aid_application = legal_aid_application
    @state_benefit_codes = {}
  end

  def call
    load_state_benefit_types
    @legal_aid_application.bank_transactions.credit.each { |txn| process_transaction(txn) }
  end

  private

  def benefit_transaction_type
    @benefit_transaction_type ||= TransactionType.find_by(name: 'benefits')
  end

  def process_transaction(txn)
    identify_state_benefit(txn) if state_benefit_payment_pattern?(txn.description)
  end

  def load_state_benefit_types
    state_benefit_list = CFE::ObtainStateBenefitTypesService.call
    state_benefit_list.each do |state_benefit|
      next if state_benefit['dwp_code'].nil?

      @state_benefit_codes[state_benefit['dwp_code']] = state_benefit['label']
    end
  end

  def identify_state_benefit(txn)
    dwp_code = regex_pattern.match(txn.description)[1]
    txn.update(transaction_type_id: benefit_transaction_type.id, meta_data: determine_label(dwp_code))
    add_legal_aid_application_transaction_type
  end

  def determine_label(dwp_code)
    @state_benefit_codes.key?(dwp_code) ? @state_benefit_codes[dwp_code] : "Unknown code #{dwp_code}"
  end

  def state_benefit_payment_pattern?(description)
    regex_pattern.match?(description)
  end

  def regex_pattern
    @regex_pattern ||= Regexp.new("^DWP\s#{nino}\s(\\S{2,6})$")
  end

  def nino
    @nino || @legal_aid_application.applicant.national_insurance_number
  end

  def add_legal_aid_application_transaction_type
    return if @legal_aid_application.transaction_types.include?(benefit_transaction_type)

    @legal_aid_application.transaction_types << benefit_transaction_type
    @legal_aid_application.save!
  end
end
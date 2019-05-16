module CCMS
  class AddApplicantService < BaseSubmissionService
    def call
      @response = applicant_add_requestor.call
      if applicant_add_response_parser.success?
        submission.applicant_add_transaction_id = applicant_add_requestor.transaction_request_id
        create_history('case_ref_obtained', submission.aasm_state) if submission.submit_applicant!
      else
        handle_failure(@response)
      end
    rescue CcmsError, StandardError => e # TODO: Replace `StandardError` with list of known expected errors
      handle_failure(e)
    end

    private

    def applicant_add_requestor
      @applicant_add_requestor ||= ApplicantAddRequestor.new(submission.legal_aid_application.applicant)
    end

    def applicant_add_response_parser
      @applicant_add_response_parser ||= ApplicantAddResponseParser.new(applicant_add_requestor.transaction_request_id, @response)
    end
  end
end

module CCMS
  module Submitters
    class ObtainApplicantReferenceService < BaseSubmissionService
      def call
        tx_id = applicant_search_requestor.transaction_request_id
        parser = CCMS::Parsers::ApplicantSearchResponseParser.new(tx_id, response)
        process_records(parser)
      rescue CcmsError => e
        handle_exception(e, xml_request)
      end

      def response
        @response ||= applicant_search_requestor.call
      end

      private

      def applicant_search_requestor
        @applicant_search_requestor ||= CCMS::Requestors::ApplicantSearchRequestor.new(legal_aid_application.applicant, legal_aid_application.provider.username)
      end

      def process_records(parser) # rubocop:disable Metrics/AbcSize
        if parser.record_count.to_i.zero?
          create_history(:case_ref_obtained, submission.aasm_state, xml_request, response)
          CCMS::Submitters::AddApplicantService.new(submission).call
        else
          submission.applicant_ccms_reference = parser.applicant_ccms_reference
          submission.save!
          create_history(:case_ref_obtained, submission.aasm_state, xml_request, response) if submission.obtain_applicant_ref!
        end
      end

      def legal_aid_application
        submission.legal_aid_application
      end

      def xml_request
        @xml_request ||= applicant_search_requestor.formatted_xml
      end
    end
  end
end

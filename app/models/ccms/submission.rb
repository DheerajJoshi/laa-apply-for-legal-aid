module CCMS
  class Submission < ApplicationRecord
    include CCMSSubmissionStateMachine

    belongs_to :legal_aid_application
    has_many :submission_documents, dependent: :destroy
    has_many :submission_history, dependent: :destroy

    validates :legal_aid_application_id, presence: true

    after_save do
      ActiveSupport::Notifications.instrument 'dashboard.ccms_submission_saved', id: id, state: aasm_state
    end

    POLL_LIMIT = Rails.env.development? ? 99 : 10

    def process!(options = {}) # rubocop:disable Metrics/MethodLength
      case aasm_state
      when 'initialised'
        CCMS::Submitters::ObtainCaseReferenceService.call(self)
      when 'case_ref_obtained'
        CCMS::Submitters::ObtainApplicantReferenceService.call(self)
      when 'applicant_submitted'
        CCMS::Submitters::CheckApplicantStatusService.call(self)
      when 'applicant_ref_obtained'
        CCMS::Submitters::ObtainDocumentIdService.call(self)
      when 'document_ids_obtained'
        CCMS::Submitters::AddCaseService.call(self, options)
      when 'case_submitted'
        CCMS::Submitters::CheckCaseStatusService.call(self)
      when 'case_created'
        CCMS::Submitters::UploadDocumentsService.call(self)
      else
        raise CcmsError, "Submission #{id} - Unknown state: #{aasm_state}"
      end
    end

    def process_async!
      SubmissionProcessWorker.perform_async(id, aasm_state)
    end
  end
end

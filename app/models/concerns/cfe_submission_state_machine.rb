module CFESubmissionStateMachine
  extend ActiveSupport::Concern

  included do
    include AASM

    aasm do
      state :initialised, initial: true
      state :assessment_created
      state :applicant_created
      state :capitals_created
      state :vehicles_created
      state :properties_created
      state :dependants_created
      state :state_benefits_created
      state :other_income_created
      state :results_obtained
      state :failed

      event :assessment_created do
        transitions from: :initialised, to: :assessment_created
      end

      event :applicant_created do
        transitions from: :assessment_created, to: :applicant_created
      end

      event :capitals_created do
        transitions from: :applicant_created, to: :capitals_created
      end

      event :vehicles_created do
        transitions from: :capitals_created, to: :vehicles_created
      end

      event :properties_created do
        transitions from: :vehicles_created, to: :properties_created
      end

      event :dependants_created do
        transitions from: :properties_created, to: :dependants_created, guard: :non_passported?
      end

      event :state_benefits_created do
        transitions from: :dependants_created, to: :state_benefits_created, guard: :non_passported?
      end

      event :other_income_created do
        transitions from: :state_benefits_created, to: :other_income_created, guard: :non_passported?
      end

      event :results_obtained do
        transitions from: :properties_created, to: :results_obtained, guard: :passported?
        transitions from: :other_income_created, to: :results_obtained
      end

      event :fail do
        transitions from: :initialised, to: :failed
        transitions from: :assessment_created, to: :failed
        transitions from: :applicant_created, to: :failed
        transitions from: :capitals_created, to: :failed
        transitions from: :properties_created, to: :failed
        transitions from: :vehicles_created, to: :failed
        transitions from: :dependants_created, to: :failed
        transitions from: :state_benefits_created, to: :failed
        transitions from: :other_income_created, to: :failed
      end
    end
  end
end

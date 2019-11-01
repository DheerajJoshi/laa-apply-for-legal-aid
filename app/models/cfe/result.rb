module CFE
  class Result < ApplicationRecord
    belongs_to :legal_aid_application
    belongs_to :submission

    def result_hash
      JSON.parse(result, symbolize_names: true)
    end

    def capital_contribution_required?
      assessment_result == 'contribution_required'
    end

    def assessment_result
      result_hash[:assessment_result]
    end

    def capital_contribution
      result_hash[:capital][:capital_contribution].to_d
    end

    def capital
      result_hash[:capital]
    end

    def property
      result_hash[:property]
    end

    def main_home
      property[:main_home]
    end

    def main_home_value
      main_home[:value].to_d
    end

    def main_home_outstanding_mortgage
      main_home[:allowable_outstanding_mortgage].to_d * -1
    end

    def main_home_disregards_and_deductions
      main_home_transaction_allowance + main_home_equity_disregard
    end

    def main_home_transaction_allowance
      main_home[:transaction_allowance].to_d * -1
    end

    def main_home_equity_disregard
      main_home[:main_home_equity_disregard].to_d * -1
    end

    def main_home_assessed_equity
      main_home[:assessed_equity].to_d.positive? ? main_home[:assessed_equity].to_d : 0.0
    end

    def additional_property?
      property[:additional_properties]&.any?
    end

    def additional_property
      property[:additional_properties].first
    end

    def additional_property_value
      additional_property[:value].to_d
    end

    def additional_property_transaction_allowance
      additional_property[:transaction_allowance].to_d * -1
    end

    def additional_property_mortgage
      additional_property[:allowable_outstanding_mortgage].to_d * -1
    end

    def vehicle
      result_hash[:vehicles][:vehicles].first
    end

    def vehicles?
      result_hash[:vehicles][:vehicles].any?
    end

    def vehicle_value
      vehicle[:value].to_d
    end

    def vehicle_loan_amount_outstanding
      vehicle[:loan_amount_outstanding].to_d
    end

    def vehicle_disregard
      vehicle_value - vehicle_assessed_amount
    end

    def vehicle_assessed_amount
      vehicle[:assessed_amount].to_d
    end

    def non_liquid_capital_items
      capital[:non_liquid_capital_items]
    end

    def liquid_capital_items
      capital[:liquid_capital_items]
    end

    def total_property
      property[:total_property]
    end

    def total_vehicles
      result_hash[:vehicles][:total_vehicle]
    end

    def total_savings
      capital[:total_liquid]
    end

    def total_other_assets
      total = capital[:total_non_liquid].to_d
      if additional_property?
        total += additional_property_value
        total += additional_property_transaction_allowance
        total += additional_property_mortgage
      end
      total
    end
  end
end

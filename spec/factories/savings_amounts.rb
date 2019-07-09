FactoryBot.define do
  factory :savings_amount do
    legal_aid_application

    trait :with_values do
      isa { rand(1...1_000_000.0).round(2) }
      cash { rand(1...1_000_000.0).round(2) }
      other_person_account { rand(1...1_000_000.0).round(2) }
      national_savings { rand(1...1_000_000.0).round(2) }
      plc_shares { rand(1...1_000_000.0).round(2) }
      peps_unit_trusts_capital_bonds_gov_stocks { rand(1...1_000_000.0).round(2) }
      life_assurance_endowment_policy { rand(1...1_000_000.0).round(2) }
    end

    trait :all_nil do
      isa { nil }
      cash { nil }
      other_person_account { nil }
      national_savings { nil }
      plc_shares { nil }
      peps_unit_trusts_capital_bonds_gov_stocks { nil }
      life_assurance_endowment_policy { nil }
    end

    trait :all_zero do
      isa { 0.0 }
      cash { 0.0 }
      other_person_account { 0.0 }
      national_savings { 0.0 }
      plc_shares { 0.0 }
      peps_unit_trusts_capital_bonds_gov_stocks { 0.0 }
      life_assurance_endowment_policy { 0.0 }
    end

    trait :mix_of_values do
      isa { nil }
      cash { 0.0 }
      other_person_account { rand(1...1_000_000.0).round(2) }
      national_savings { nil }
      plc_shares { 0.0 }
      peps_unit_trusts_capital_bonds_gov_stocks { rand(1...1_000_000.0).round(2) }
      life_assurance_endowment_policy { 0.0 }
    end
  end
end

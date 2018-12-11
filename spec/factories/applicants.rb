FactoryBot.define do
  factory :applicant do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { Faker::Date.birthday }
    email { Faker::Internet.safe_email }
    national_insurance_number { Faker::Base.regexify(Applicant::NINO_REGEXP) }
    uses_online_banking { [true, false].sample }

    trait :with_address do
      addresses { build_list :address, 1 }
    end

    trait :with_address_lookup do
      addresses { build_list :address, 1, :is_lookup_used }
    end
  end
end

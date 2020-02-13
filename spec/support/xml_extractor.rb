class XmlExtractor
  # rubocop:disable Layout/LineLength
  XPATHS = {
    global_means: '/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity/Instances/Attributes/Attribute',
    global_merits: '/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeritsAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity/Instances/Attributes/Attribute',
    proceeding: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "PROCEEDING"]//Attributes/Attribute),
    proceeding_merits: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeritsAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "PROCEEDING"]//Attributes/Attribute),
    opponent: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeritsAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "OPPONENT_OTHER_PARTIES"]//Attributes/Attribute),
    proceeding_case_id: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/Proceedings/Proceeding/ProceedingCaseID),
    family_statement: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeritsAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "FAMILY_STATEMENT"]//Attributes/Attribute),
    main_dwelling: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeritsAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "MAIN_DWELLING"]//Attributes/Attribute),
    vehicle_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "CARS_AND_MOTOR_VEHICLES"]//Attributes/Attribute),
    vehicle_sequence_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "CARS_AND_MOTOR_VEHICLES"]),
    wage_slip_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "CLI_NON_HM_WAGE_SLIP"]),
    bank_accounts_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "BANKACC"]),
    other_party: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "OPPONENT_OTHER_PARTIES"]//Attributes/Attribute),
    valuable_possessions_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "VALUABLE_POSSESSION"]),
    means_proceeding_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "PROCEEDING"]),
    employment_entity: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeansAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "EMPLOYMENT_CLIENT"]),
    change_in_circumstances: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/MeritsAssesments/AssesmentResults/AssesmentDetails/AssessmentScreens/Entity[EntityName = "CHANGE_IN_CIRCUMSTANCES"]//Attributes/Attribute),
    devolved_powers_date: %(/Envelope/Body/CaseAddRQ/Case/CaseDetails/ApplicationDetails/DevolvedPowersDate),
    national_savings: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "CLINATIONAL"]//Attributes/Attribute),
    plc_shares: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "CAPITAL_SHARE"]//Attributes/Attribute),
    financial_support: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "CLIENT_FINANCIAL_SUPPORT"]//Attributes/Attribute),
    change_in_circumstance: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "CHANGE_IN_CIRCUMSTANCE"]//Attributes/Attribute),
    first_bank_acct_instance: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "BANKACC"]//Instances[1]/Attributes/Attribute),
    other_capital: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "OTHER_CAPITAL"]//Attributes/Attribute),
    other_savings: %(//MeansAssesments//AssesmentDetails//Entity[EntityName = "OTHERSAVING"]//Attributes/Attribute)

  }.freeze
  # rubocop:enable Layout/LineLength

  def self.call(xml, section, attribute_name = nil)
    new(xml, section, attribute_name).extract
  end

  def initialize(xml, section, attribute_name)
    @xml = xml
    @section = section
    @attribute_name = attribute_name
  end

  def extract
    doc = Nokogiri::XML(@xml).remove_namespaces!
    xpath = if @attribute_name.nil?
              (XPATHS[@section]).to_s
            else
              "#{XPATHS[@section]}[Attribute='#{@attribute_name}']"
            end

    doc.xpath(xpath)
  end
end

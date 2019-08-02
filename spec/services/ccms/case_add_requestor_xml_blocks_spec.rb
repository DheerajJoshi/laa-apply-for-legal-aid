require 'rails_helper'

module CCMS # rubocop:disable Metrics/ModuleLength
  RSpec.describe CaseAddRequestor do
    context 'XML request' do
      let(:expected_tx_id) { '201904011604570390059770666' }
      let(:legal_aid_application) do
        create :legal_aid_application,
               :with_proceeding_types,
               :with_everything,
               populate_vehicle: true,
               with_bank_accounts: 2
      end
      let(:respondent) { legal_aid_application.respondent }
      let(:submission) { create :submission, :case_ref_obtained, legal_aid_application: legal_aid_application }
      let(:requestor) { described_class.new(submission, {}) }
      let(:xml) { requestor.formatted_xml }
      before { allow(requestor).to receive(:transaction_request_id).and_return(expected_tx_id) }

      context 'DELEGATED_FUNCTIONS_DATE blocks' do
        context 'delegated functions used' do
          before do
            legal_aid_application.update(used_delegated_functions_on: Date.today, used_delegated_functions: true)
          end

          it 'generates the delegated functions block in the means assessment section' do
            block = XmlExtractor.call(xml, :global_means, 'DELEGATED_FUNCTIONS_DATE')
            expect(block).to be_present
            expect(block).to have_response_type('date')
            expect(block).to have_response_value(Date.today.strftime('%d-%m-%Y'))
          end

          it 'generates the delegated functions block in the merits assessment section' do
            block = XmlExtractor.call(xml, :global_merits, 'DELEGATED_FUNCTIONS_DATE')
            expect(block).to be_present
            expect(block).to have_response_type('date')
            expect(block).to have_response_value(Date.today.strftime('%d-%m-%Y'))
          end
        end

        context 'delegated functions not used' do
          it 'does not generate the delegated functions block in the means assessment section' do
            block = XmlExtractor.call(xml, :global_means, 'DELEGATED_FUNCTIONS_DATE')
            expect(block).not_to be_present
          end

          it 'does not generates the delegated functions block in the merits assessment section' do
            block = XmlExtractor.call(xml, :global_merits, 'DELEGATED_FUNCTIONS_DATE')
            expect(block).not_to be_present
          end
        end
      end

      context 'POLICE_NOTIFIED block' do
        context 'police notified' do
          before { respondent.update(police_notified: true) }
          it 'is true' do
            block = XmlExtractor.call(xml, :global_merits, 'POLICE_NOTIFIED')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'true'
          end
        end

        context 'police NOT notified' do
          before { respondent.update(police_notified: false) }
          it 'is false' do
            block = XmlExtractor.call(xml, :global_merits, 'POLICE_NOTIFIED')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'false'
          end
        end
      end

      context 'WARNING_LETTER_SENT & INJ_REASON_NO_WARNING_LETTER blocks' do
        context 'not sent' do
          before { respondent.update(warning_letter_sent: false) }
          it 'generates WARNING_LETTER_SENT block with false value' do
            block = XmlExtractor.call(xml, :global_merits, 'WARNING_LETTER_SENT')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'false'
          end

          it 'generates INJ_REASON_NO_WARNING_LETTER block with reason' do
            block = XmlExtractor.call(xml, :global_merits, 'INJ_REASON_NO_WARNING_LETTER')
            expect(block).to be_present
            expect(block).to have_response_type 'text'
            expect(block).to have_response_value legal_aid_application.respondent.warning_letter_sent_details
          end
        end

        context 'sent' do
          it 'generates WARNING_LETTER_SENT block with true value' do
            respondent.update(warning_letter_sent: true)
            block = XmlExtractor.call(xml, :global_merits, 'WARNING_LETTER_SENT')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'true'
          end

          it 'does not generates INJ_REASON_NO_WARNING_LETTER block' do
            respondent.update(warning_letter_sent: true)
            block = XmlExtractor.call(xml, :global_merits, 'INJ_REASON_NO_WARNING_LETTER')
            expect(block).not_to be_present
          end
        end
      end

      context 'INJ_RESPONDENT_CAPACITY' do
        context 'respondent has capacity' do
          before { respondent.understands_terms_of_court_order = true }
          it 'is true' do
            block = XmlExtractor.call(xml, :global_merits, 'INJ_RESPONDENT_CAPACITY')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'true'
          end
        end

        context 'respondent does not have capacity' do
          before { respondent.understands_terms_of_court_order = false }
          it 'is false' do
            block = XmlExtractor.call(xml, :global_merits, 'INJ_RESPONDENT_CAPACITY')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'false'
          end
        end
      end

      context 'PROC_MATTER_TYPE_MEANING' do
        it 'should be the meaning from the proceeding type record' do
          block = XmlExtractor.call(xml, :global_merits, 'PROC_MATTER_TYPE_MEANING')
          expect(block).to be_present
          expect(block).to have_response_type 'text'
          expect(block).to have_response_value legal_aid_application.lead_proceeding_type.meaning
        end
      end

      context 'attributes hard coded to true' do
        it 'should be hard coded to true' do
          attributes = [
            [:global_means, 'LAR_SCOPE_FLAG'],
            [:global_means, 'GB_INPUT_B_38WP3_2SCREEN'],
            [:global_means, 'GB_INPUT_B_38WP3_3SCREEN'],
            [:global_merits, 'MERITS_DECLARATION_SCREEN'],
            [:global_means, 'GB_DECL_B_38WP3_13A'],
            [:global_merits, 'CLIENT_HAS_DV_RISK'],
            [:global_merits,  'CLIENT_REQ_SEP_REP'],
            [:global_merits,  'DECLARATION_WILL_BE_SIGNED'],
            [:global_merits,  'DECLARATION_REVOKE_IMP_SUBDP'],
            [:proceeding, 'SCOPE_LIMIT_IS_DEFAULT'],
            [:proceeding_merits,  'LEAD_PROCEEDING'],
            [:proceeding_merits,  'SCOPE_LIMIT_IS_DEFAULT']
          ]
          attributes.each do |entity_attribute_pair|
            entity, attribute = entity_attribute_pair
            block = XmlExtractor.call(xml, entity, attribute)
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'true'
          end
        end
      end

      context 'BAIL_CONDITIONS_SET' do
        context 'bail conditions set' do
          before { respondent.bail_conditions_set = true }
          it 'is true' do
            block = XmlExtractor.call(xml, :global_merits, 'BAIL_CONDITIONS_SET')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'true'
          end
        end

        context 'bail conditions NOT set' do
          before { respondent.bail_conditions_set = false }
          it 'is false' do
            block = XmlExtractor.call(xml, :global_merits, 'BAIL_CONDITIONS_SET')
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'false'
          end
        end
      end

      context 'APP_AMEND_TYPE' do
        context 'delegated function used' do
          context 'in global_merits section' do
            it 'returns SUBDP' do
              allow(legal_aid_application).to receive(:used_delegated_functions?).and_return(true)
              allow(legal_aid_application).to receive(:used_delegated_functions_on).and_return(Date.today)
              block = XmlExtractor.call(xml, :global_merits, 'APP_AMEND_TYPE')
              expect(block).to be_present
              expect(block).to have_response_type 'text'
              expect(block).to have_response_value 'SUBDP'
            end

            context 'in global_means section;' do
              it 'returns SUBDP' do
                allow(legal_aid_application).to receive(:used_delegated_functions?).and_return(true)
                allow(legal_aid_application).to receive(:used_delegated_functions_on).and_return(Date.today)
                block = XmlExtractor.call(xml, :global_means, 'APP_AMEND_TYPE')
                expect(block).to be_present
                expect(block).to have_response_type 'text'
                expect(block).to have_response_value 'SUBDP'
              end
            end
          end
        end

        context 'delegated functions not used' do
          context 'in global_merits section' do
            it 'returns SUB' do
              block = XmlExtractor.call(xml, :global_merits, 'APP_AMEND_TYPE')
              expect(block).to be_present
              expect(block).to have_response_type 'text'
              expect(block).to have_response_value 'SUB'
            end

            context 'in global_means section;' do
              it 'returns SUB' do
                block = XmlExtractor.call(xml, :global_means, 'APP_AMEND_TYPE')
                expect(block).to be_present
                expect(block).to have_response_type 'text'
                expect(block).to have_response_value 'SUB'
              end
            end
          end
        end

        context 'attributes hard coded to false' do
          it 'should be type of text hard coded to false' do
            attributes = [
              [:global_means, 'COST_LIMIT_CHANGED_FLAG']
            ]
            attributes.each do |entity_attribute_pair|
              entity, attribute = entity_attribute_pair
              block = XmlExtractor.call(xml, entity, attribute)
              expect(block).to be_present
              expect(block).to have_response_type 'text'
              expect(block).to have_response_value 'false'
            end
          end
        end

        it 'should be type of boolean hard coded to false' do
          attributes = [
            [:global_means, 'GB_INFER_B_1WP1_1A'],
            [:global_means, 'GB_INPUT_B_14WP2_7A'],
            [:global_means, 'GB_INPUT_B_17WP2_7A'],
            [:global_means, 'GB_INPUT_B_18WP2_2A'],
            [:global_means, 'GB_INPUT_B_18WP2_4A'],
            [:global_means, 'GB_INPUT_B_1WP1_2A'],
            [:global_means, 'GB_INPUT_B_1WP3_175A'],
            [:global_means, 'GB_INPUT_B_1WP4_1B'],
            [:global_means, 'GB_INPUT_B_1WP4_2B'],
            [:global_means, 'GB_INPUT_B_1WP4_3B'],
            [:global_means, 'GB_INPUT_B_39WP3_70B'],
            [:global_means, 'GB_INPUT_B_41WP3_40A'],
            [:global_means, 'GB_INPUT_B_5WP1_22A'],
            [:global_means, 'GB_INPUT_B_5WP1_3A'],
            [:global_means, 'GB_INPUT_B_8WP2_1A'],
            [:global_means, 'GB_PROC_B_39WP3_14A'],
            [:global_means, 'GB_PROC_B_39WP3_15A'],
            [:global_means, 'GB_PROC_B_39WP3_16A'],
            [:global_means, 'GB_PROC_B_39WP3_17A'],
            [:global_means, 'GB_PROC_B_39WP3_18A'],
            [:global_means, 'GB_PROC_B_39WP3_19A'],
            [:global_means, 'GB_PROC_B_39WP3_1A'],
            [:global_means, 'GB_PROC_B_39WP3_20A'],
            [:global_means, 'GB_PROC_B_39WP3_21A'],
            [:global_means, 'GB_PROC_B_39WP3_22A'],
            [:global_means, 'GB_PROC_B_39WP3_23A'],
            [:global_means, 'GB_PROC_B_39WP3_24A'],
            [:global_means, 'GB_PROC_B_39WP3_25A'],
            [:global_means, 'GB_PROC_B_39WP3_29A'],
            [:global_means, 'GB_PROC_B_39WP3_2A'],
            [:global_means, 'GB_PROC_B_39WP3_30A'],
            [:global_means, 'GB_PROC_B_39WP3_31A'],
            [:global_means, 'GB_PROC_B_39WP3_32A'],
            [:global_means, 'GB_PROC_B_39WP3_33A'],
            [:global_means, 'GB_PROC_B_39WP3_34A'],
            [:global_means, 'GB_PROC_B_39WP3_35A'],
            [:global_means, 'GB_PROC_B_39WP3_36A'],
            [:global_means, 'GB_PROC_B_39WP3_37A'],
            [:global_means, 'GB_PROC_B_39WP3_38A'],
            [:global_means, 'GB_PROC_B_39WP3_39A'],
            [:global_means, 'GB_PROC_B_39WP3_40A'],
            [:global_means, 'GB_PROC_B_39WP3_41A'],
            [:global_means, 'GB_PROC_B_39WP3_42A'],
            [:global_means, 'GB_PROC_B_39WP3_46A'],
            [:global_means, 'GB_PROC_B_39WP3_47A'],
            [:global_means, 'GB_PROC_B_39WP3_7A'],
            [:global_means, 'GB_PROC_B_39WP3_8A'],
            [:global_means, 'GB_PROC_B_40WP3_10A'],
            [:global_means, 'GB_PROC_B_40WP3_13A'],
            [:global_means, 'GB_PROC_B_40WP3_15A'],
            [:global_means, 'GB_PROC_B_40WP3_17A'],
            [:global_means, 'GB_PROC_B_40WP3_19A'],
            [:global_means, 'GB_PROC_B_40WP3_1A'],
            [:global_means, 'GB_PROC_B_40WP3_21A'],
            [:global_means, 'GB_PROC_B_40WP3_23A'],
            [:global_means, 'GB_PROC_B_40WP3_25A'],
            [:global_means, 'GB_PROC_B_40WP3_27A'],
            [:global_means, 'GB_PROC_B_40WP3_29A'],
            [:global_means, 'GB_PROC_B_40WP3_2A'],
            [:global_means, 'GB_PROC_B_40WP3_31A'],
            [:global_means, 'GB_PROC_B_40WP3_33A'],
            [:global_means, 'GB_PROC_B_40WP3_35A'],
            [:global_means, 'GB_PROC_B_40WP3_39A'],
            [:global_means, 'GB_PROC_B_40WP3_3A'],
            [:global_means, 'GB_PROC_B_40WP3_40A'],
            [:global_means, 'GB_PROC_B_40WP3_41A'],
            [:global_means, 'GB_PROC_B_40WP3_42A'],
            [:global_means, 'GB_PROC_B_40WP3_43A'],
            [:global_means, 'GB_PROC_B_40WP3_44A'],
            [:global_means, 'GB_PROC_B_40WP3_45A'],
            [:global_means, 'GB_PROC_B_40WP3_46A'],
            [:global_means, 'GB_PROC_B_40WP3_47A'],
            [:global_means, 'GB_PROC_B_40WP3_48A'],
            [:global_means, 'GB_PROC_B_40WP3_49A'],
            [:global_means, 'GB_PROC_B_40WP3_4A'],
            [:global_means, 'GB_PROC_B_40WP3_50A'],
            [:global_means, 'GB_PROC_B_40WP3_51A'],
            [:global_means, 'GB_PROC_B_40WP3_52A'],
            [:global_means, 'GB_PROC_B_40WP3_53A'],
            [:global_means, 'GB_PROC_B_40WP3_54A'],
            [:global_means, 'GB_PROC_B_40WP3_55A'],
            [:global_means, 'GB_PROC_B_40WP3_56A'],
            [:global_means, 'GB_PROC_B_40WP3_57A'],
            [:global_means, 'GB_PROC_B_40WP3_58A'],
            [:global_means, 'GB_PROC_B_40WP3_9A'],
            [:global_means, 'GB_PROC_B_41WP3_10A'],
            [:global_means, 'GB_PROC_B_41WP3_11A'],
            [:global_means, 'GB_PROC_B_41WP3_12A'],
            [:global_means, 'GB_PROC_B_41WP3_13A'],
            [:global_means, 'GB_PROC_B_41WP3_14A'],
            [:global_means, 'GB_PROC_B_41WP3_15A'],
            [:global_means, 'GB_PROC_B_41WP3_16A'],
            [:global_means, 'GB_PROC_B_41WP3_17A'],
            [:global_means, 'GB_PROC_B_41WP3_18A'],
            [:global_means, 'GB_PROC_B_41WP3_1A'],
            [:global_means, 'GB_PROC_B_41WP3_20A'],
            [:global_means, 'GB_PROC_B_41WP3_2A'],
            [:global_means, 'GB_PROC_B_41WP3_3A'],
            [:global_means, 'GB_PROC_B_41WP3_4A'],
            [:global_means, 'GB_PROC_B_41WP3_5A'],
            [:global_means, 'GB_PROC_B_41WP3_6A'],
            [:global_means, 'GB_PROC_B_41WP3_7A'],
            [:global_means, 'GB_PROC_B_41WP3_8A'],
            [:global_means, 'GB_PROC_B_41WP3_9A'],
            [:global_means, 'GB_RFLAG_B_2WP3_01A'],
            [:global_means, 'GB_ROUT_B_43WP3_13A'],
            [:global_means, 'HIGH_PROFILE'],
            [:global_means, 'LAR_PROC_B_39WP3_53A'],
            [:global_means, 'LAR_PROC_B_39WP3_54A'],
            [:global_means, 'LAR_PROC_B_40WP3_29A'],
            [:global_means, 'LAR_PROC_B_40WP3_30A'],
            [:global_means, 'LAR_PROC_B_40WP3_31A'],
            [:global_means, 'LAR_PROC_B_40WP3_32A'],
            [:global_merits, 'ACTION_AGAINST_POLICE'],
            [:global_merits, 'ACTUAL_LIKELY_COSTS_EXCEED_25K'],
            [:global_merits, 'AMENDMENT'],
            [:global_merits, 'APP_BROUGHT_BY_PERSONAL_REP'],
            [:global_merits, 'CLIENT_HAS_RECEIVED_LA_BEFORE'],
            [:global_merits, 'COURT_ATTEND_IN_LAST_12_MONTHS'],
            [:global_merits, 'ECF_FLAG'],
            [:global_merits, 'EVID_DEC_AGAINST_INSTRUCTIONS'],
            [:global_merits, 'EVIDENCE_AMD_CORRESPONDENCE'],
            [:global_merits, 'EVIDENCE_AMD_COUNSEL_OPINION'],
            [:global_merits, 'EVIDENCE_AMD_COURT_ORDER'],
            [:global_merits, 'EVIDENCE_AMD_EXPERT_RPT'],
            [:global_merits, 'EVIDENCE_AMD_PLEADINGS'],
            [:global_merits, 'EVIDENCE_AMD_SOLICITOR_RPT'],
            [:global_merits, 'EVIDENCE_CA_CRIME_PROCS'],
            [:global_merits, 'EVIDENCE_CA_FINDING_FACT'],
            [:global_merits, 'EVIDENCE_CA_INJ_PSO'],
            [:global_merits, 'EVIDENCE_CA_POLICE_BAIL'],
            [:global_merits, 'EVIDENCE_CA_POLICE_CAUTION'],
            [:global_merits, 'EVIDENCE_CA_PROTECTIVE_INJ'],
            [:global_merits, 'EVIDENCE_CA_SOCSERV_ASSESS'],
            [:global_merits, 'EVIDENCE_CA_SOCSERV_LTTR'],
            [:global_merits, 'EVIDENCE_CA_UNSPENT_CONVICTION'],
            [:global_merits, 'EVIDENCE_COPY_PR_ORDER'],
            [:global_merits, 'EVIDENCE_DV_CONVICTION'],
            [:global_merits, 'EVIDENCE_DV_COURT_ORDER'],
            [:global_merits, 'EVIDENCE_DV_CRIM_PROCS_2A'],
            [:global_merits, 'EVIDENCE_DV_DVPN_2'],
            [:global_merits, 'EVIDENCE_DV_FIN_ABUSE'],
            [:global_merits, 'EVIDENCE_DV_FINDING_FACT_2A'],
            [:global_merits, 'EVIDENCE_DV_HEALTH_LETTER'],
            [:global_merits, 'EVIDENCE_DV_HOUSING_AUTHORITY'],
            [:global_merits, 'EVIDENCE_DV_IDVA'],
            [:global_merits, 'EVIDENCE_DV_IMMRULES_289A'],
            [:global_merits, 'EVIDENCE_DV_PARTY_ON_BAIL_2A'],
            [:global_merits, 'EVIDENCE_DV_POLICE_CAUTION_2A'],
            [:global_merits, 'EVIDENCE_DV_PROT_INJUNCT'],
            [:global_merits, 'EVIDENCE_DV_PUB_BODY'],
            [:global_merits, 'EVIDENCE_DV_PUBLIC_BODY'],
            [:global_merits, 'EVIDENCE_DV_REFUGE'],
            [:global_merits, 'EVIDENCE_DV_SUPP_SERVICE'],
            [:global_merits, 'EVIDENCE_DV_SUPPORT_ORG'],
            [:global_merits, 'EVIDENCE_DV_UNDERTAKING_2A'],
            [:global_merits, 'EVIDENCE_EXISTING_COUNSEL_OP'],
            [:global_merits, 'EVIDENCE_EXISTING_CT_ORDER'],
            [:global_merits, 'EVIDENCE_EXISTING_EXPERT_RPT'],
            [:global_merits, 'EVIDENCE_EXISTING_STATEMENT'],
            [:global_merits, 'EVIDENCE_EXPERT_REPORT'],
            [:global_merits, 'EVIDENCE_ICACU_LETTER'],
            [:global_merits, 'EVIDENCE_IQ_CORONER_CORR'],
            [:global_merits, 'EVIDENCE_IQ_COSTS_SCHEDULE'],
            [:global_merits, 'EVIDENCE_IQ_REPORT_ON_DEATH'],
            [:global_merits, 'EVIDENCE_LETTER_BEFORE_ACTION'],
            [:global_merits, 'EVIDENCE_MEDIATOR_APP7A'],
            [:global_merits, 'EVIDENCE_OMBUDSMAN_COMP_RPT'],
            [:global_merits, 'EVIDENCE_PLEADINGS_REQUIRED'],
            [:global_merits, 'EVIDENCE_PR_AGREEMENT'],
            [:global_merits, 'EVIDENCE_PRE_ACTION_DISCLOSURE'],
            [:global_merits, 'EVIDENCE_RELEVANT_CORR_ADR'],
            [:global_merits, 'EVIDENCE_RELEVANT_CORR_SETTLE'],
            [:global_merits, 'EVIDENCE_WARNING_LETTER'],
            [:global_merits, 'EXISTING_COUNSEL_OPINION'],
            [:global_merits, 'EXISTING_EXPERT_REPORTS'],
            [:global_merits, 'FH_LOWER_PROVIDED'],
            [:global_merits, 'HIGH_PROFILE'],
            [:global_merits, 'LEGAL_HELP_PROVIDED'],
            [:global_merits, 'MENTAL_HEAL_ACT_MENTAL_CAP_ACT'],
            [:global_merits, 'NEGOTIATION_CORRESPONDENCE'],
            [:global_merits, 'OTHER_PARTIES_MAY_BENEFIT'],
            [:global_merits, 'OTHERS_WHO_MAY_BENEFIT'],
            [:global_merits, 'PROCS_ARE_BEFORE_THE_COURT'],
            [:global_merits, 'UPLOAD_SEPARATE_STATEMENT'],
            [:global_merits, 'URGENT_FLAG'],
            [:global_merits, 'COST_LIMIT_CHANGED'],
            [:global_merits, 'DECLARATION_IDENTIFIER']
          ]
          attributes.each do |entity_attribute_pair|
            entity, attribute = entity_attribute_pair
            block = XmlExtractor.call(xml, entity, attribute)
            expect(block).to be_present
            expect(block).to have_response_type 'boolean'
            expect(block).to have_response_value 'false'
          end
        end
      end
    end
  end
end

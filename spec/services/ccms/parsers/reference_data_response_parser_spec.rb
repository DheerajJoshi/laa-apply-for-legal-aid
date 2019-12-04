require 'rails_helper'

module CCMS
  module Parsers
    RSpec.describe ReferenceDataResponseParser do
      describe '#reference_id' do
        let(:response_xml) { ccms_data_from_file 'reference_data_response.xml' }
        let(:expected_tx_id) { '20190301030405123456' }
        let(:expected_reference_number) { '300000135140' }

        it 'extracts the reference data' do
          parser = described_class.new(expected_tx_id, response_xml)
          expect(parser.reference_id).to eq expected_reference_number
        end

        it 'raises if the transaction_request_ids dont match' do
          expect {
            parser = described_class.new(Faker::Number.number(digits: 20), response_xml)
            parser.reference_id
          }.to raise_error CCMS::CcmsError, "Invalid transaction request id #{expected_tx_id}"
        end
      end
    end
  end
end

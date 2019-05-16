require 'rails_helper'

module CCMS
  RSpec.describe DocumentUploadResponseParser do
    describe '#success?' do
      let(:response_xml) { ccms_data_from_file 'document_upload_response.xml' }
      let(:expected_tx_id) { '20190301030405123456' }
      let(:expected_document_id) { '4420073' }

      it 'extracts the status' do
        parser = described_class.new(expected_tx_id, response_xml)
        expect(parser.success?).to eq true
      end

      it 'raises if the transaction_request_ids dont match' do
        expect {
          parser = described_class.new(Faker::Number.number(20), response_xml)
          parser.success?
        }.to raise_error CcmsError, 'Invalid transaction request id'
      end
    end
  end
end

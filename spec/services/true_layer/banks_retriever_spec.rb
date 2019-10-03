require 'rails_helper'

RSpec.describe TrueLayer::BanksRetriever, vcr: { cassette_name: 'true_layer_banks_api', allow_playback_repeats: true } do
  let(:group) { 'england-and-wales' }

  subject { described_class.new }

  describe '.banks' do
    it 'returns same as instance banks' do
      expect(described_class.banks).to eq(subject.banks)
    end

    context 'on failure' do
      let(:uri) { URI.parse(described_class::API_URL) }
      before do
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(OpenStruct.new)
      end
      it 'raises error' do
        expect { described_class.banks }.to raise_error(described_class::UnsuccessfulRetrievalError)
      end
    end
  end

  describe '#banks' do
    let(:banks) { subject.banks }

    it 'is an array' do
      expect(banks).to be_a(Array)
    end

    it 'contains data about the banks' do
      bank = banks.first
      expect(bank[:provider_id]).to be_a(String)
      expect(bank[:display_name]).to be_a(String)
      expect(bank[:logo_url]).to start_with('https://')
      expect(bank[:logo_url]).to end_with('.svg')
    end
  end
end

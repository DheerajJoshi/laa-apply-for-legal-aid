require 'rails_helper'

RSpec.describe Provider, type: :model do
  let(:firm) { create :firm }
  let(:provider) { create :provider, firm: firm }

  describe '#update_details' do
    context 'firm exists' do
      it 'does not call provider details creator immediately' do
        expect(ProviderDetailsCreator).not_to receive(:call).with(provider)
        provider.update_details
      end

      it 'schedules a background job' do
        expect(ProviderDetailsCreatorWorker).to receive(:perform_async).with(provider.id)
        provider.update_details
      end
    end

    context 'firm does not exist' do
      let(:firm) { nil }

      it 'updates provider details immediately' do
        expect(ProviderDetailsCreator).to receive(:call).with(provider)
        provider.update_details
      end
    end
  end

  describe '#whitelisted_user?' do
    before do
      allow(HostEnv).to receive(:production?).and_return(true)
      Rails.configuration.x.application.whitelisted_users = %w[user1 user2 user3]
    end

    context 'user is whitelisted' do
      context 'provider username is in lower case' do
        let(:provider) { create :provider, username: Rails.configuration.x.application.whitelisted_users.sample.downcase }
        it 'returns true' do
          expect(provider.whitelisted_user?).to be true
        end
      end
      context 'provider username is in upper case' do
        let(:provider) { create :provider, username: Rails.configuration.x.application.whitelisted_users.sample.upcase }
        it 'returns true' do
          expect(provider.whitelisted_user?).to be true
        end
      end
    end
    context 'user is not whitelisted' do
      it 'returns false' do
        expect(provider.whitelisted_user?).to be false
      end
    end
  end

  describe '#user_permissions' do
    let!(:permission1) { create :permission }
    let!(:permission2) { create :permission }
    let!(:permission3) { create :permission }

    context 'no permissions for this provider, but one permission for firm' do
      before do
        firm.permissions << permission2
        firm.save!
      end

      it 'returns the firms permissions' do
        expect(provider.user_permissions).to eq [permission2]
      end
    end

    context 'permissions exist for both firm and provider' do
      before do
        firm.permissions << permission1
        firm.permissions << permission2
        firm.save!
        provider.permissions << permission3
        provider.permissions << permission1
        provider.save!
      end
      it 'returns the permission for the provider' do
        expect(provider.user_permissions).to match_array([permission1, permission3])
      end
    end
  end
end

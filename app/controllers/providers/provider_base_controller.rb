module Providers
  class ProviderBaseController < BaseController
    before_action :authenticate_provider!
    before_action :set_cache_buster
    include ApplicationDependable
    include Draftable
    include Authorizable
  end
end

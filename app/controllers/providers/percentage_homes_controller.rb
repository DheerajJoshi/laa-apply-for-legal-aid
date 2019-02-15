module Providers
  class PercentageHomesController < ProviderBaseController
    def show
      authorize @legal_aid_application
      @form = LegalAidApplications::PercentageHomeForm.new(model: legal_aid_application)
    end

    def update
      authorize @legal_aid_application
      @form = LegalAidApplications::PercentageHomeForm.new(percentage_home_params.merge(model: legal_aid_application))

      render :show unless save_continue_or_draft(@form)
    end

    private

    def percentage_home_params
      return {} unless params[:legal_aid_application]

      params.require(:legal_aid_application).permit(:percentage_home)
    end
  end
end

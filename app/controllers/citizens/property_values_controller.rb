module Citizens
  class PropertyValuesController < BaseController
    def show
      @form = Applicants::PropertyValueForm.new # this is so errors are visible
    end

    def create
      @form = Applicants::PropertyValueForm.new(edit_params)

      if @form.save
        render plain: 'Navigate to question 1c; What is the outstanding mortgage?'
      else
        render :show
      end
    end

    private

    def property_value_params
      params.fetch(:legal_aid_application, {}).permit(:property_value)
    end

    def edit_params
      property_value_params.merge(model: current_applicant.legal_aid_application)
    end
  end
end

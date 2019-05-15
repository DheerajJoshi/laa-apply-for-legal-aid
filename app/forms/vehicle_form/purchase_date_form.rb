module VehicleForm
  class PurchaseDateForm
    include BaseForm

    form_for Vehicle

    DATE_PARTS = %i[purchased_on_year purchased_on_month purchased_on_day].freeze

    attr_accessor(*DATE_PARTS)
    attr_writer :purchased_on

    validates :purchased_on,
              date: { not_in_the_future: true, allow_nil: true },
              presence: { unless: :draft_and_not_incomplete_date? }

    def purchased_on
      return @purchased_on if @purchased_on.present?
      return incomplete_date if date_values.any?(&:blank?)
      return unless Date.valid_date?(*date_values.map(&:to_i))

      @purchased_on = attributes[:purchased_on] = Date.new(*date_values.map(&:to_i))
    end

    def initialize(*args)
      super
      set_instance_variables_for_attributes_if_not_set_but_in_model(
        attrs: DATE_PARTS,
        model_attributes: purchased_on_from_model
      )
    end

    private

    def date_values
      DATE_PARTS.map { |field| __send__(field) }
    end

    def exclude_from_model
      DATE_PARTS
    end

    def purchased_on_from_model
      return unless model.purchased_on?

      {
        purchased_on_year: model.purchased_on.year,
        purchased_on_month: model.purchased_on.month,
        purchased_on_day: model.purchased_on.day
      }
    end

    def incomplete_date
      @incomplete_date = true unless date_values.all?(&:blank?)
      nil
    end

    def incomplete_date?
      @incomplete_date
    end

    def draft_and_not_incomplete_date?
      draft? && !incomplete_date?
    end
  end
end

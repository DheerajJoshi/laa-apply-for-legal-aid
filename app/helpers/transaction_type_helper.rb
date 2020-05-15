module TransactionTypeHelper
  # hints is a hash with the transaction type names as keys, and the hint texts as values
  # and only includes entries for types that need hints.
  def transaction_type_check_boxes(form:, transaction_types:, hints: {})
    hints.transform_values! { |hint| govuk_hint(hint, class: 'govuk-checkboxes__hint') }
    render(
      'shared/forms/transaction_type_check_boxes',
      form: form,
      transaction_types: transaction_types,
      hints: hints,
      label_method: "#{journey_type}_label_name"
    )
  end

  def sort_category_column_cell(object, transaction_type)
    return sort_category_column_cell_vacant(object, transaction_type) unless object.transaction_type_id?

    tag_classes = %w[table-category govuk-body-s]
    label = t("transaction_types.table_label.#{object.transaction_type.name}")
    content = gov_uk_tag(text: label, classes: tag_classes).html_safe

    # @transaction_type.name == 'excluded_benefits' ? content = '' : content = gov_uk_tag(text: label, classes: tag_classes).html_safe

    sort_column_cell(
      id: "Category-#{object.id}",
      sort_by: label,
      content: content
    )
  end

  def sort_category_column_cell_vacant(object, transaction_type)
    label = t("transaction_types.table_label.#{transaction_type.name}")
    tag_classes = %w[table-category govuk-body-s table-category-vacant]

    content = @transaction_type.name == 'excluded_benefits' ? '' : gov_uk_tag(text: label, classes: tag_classes).html_safe

    sort_column_cell(
      id: "Category-#{object.id}",
      sort_by: 'ZZZ',
      content: content
    )
  end
end

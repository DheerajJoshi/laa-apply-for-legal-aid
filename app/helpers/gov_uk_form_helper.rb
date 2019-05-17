module GovUkFormHelper
  # Wrapper for form elements:
  #   <%= govuk_form_group do %>
  #      ... input and label etc. ...
  #   <% end %>
  #
  # If `show_error_if` is passed a truthy object, GOV-UK error message styling
  # will be applied.
  #
  # Passing the ids of the hint and input elements will generate an
  # aria-describedby declaration for them within the form group statement.
  #
  def govuk_form_group(show_error_if: nil, hint_id: nil, input: nil, &block)
    content = capture(&block)
    error_class = show_error_if ? 'govuk-form-group--error' : ''
    render(
      'shared/forms/form_group',
      content: content,
      error_class: error_class,
      aria_describedby: aria_describedby(hint_id, input)
    )
  end

  def govuk_fieldset_header(text, padding_below: nil)
    padding_class = padding_below && "govuk-!-padding-bottom-#{padding_below}"
    render(
      'shared/forms/fieldset_header',
      text: text,
      padding_class: padding_class
    )
  end

  def govuk_hint(text, args = {})
    content_tag :span, text, merge_with_class(args, 'govuk-hint')
  end

  def govuk_error_message(text, args = {})
    return if text.blank?

    content_tag :span, text, merge_with_class(args, 'govuk-error-message')
  end

  def date_input_fields(prefix:, field_name:, form:, width: 'two-thirds', set_error_class_here: true)
    group_error_class = set_error_class_here && form.object.errors[field_name].any? ? 'govuk-form-group--error' : ''
    render(
      'shared/forms/date_input_fields',
      prefix: prefix,
      field_name: field_name,
      form: form,
      width: width,
      group_error_class: group_error_class
    )
  end

  # Adds or appends `class_text` to `args[:class]`. So:
  #   args = { id: 'thing' }
  #   merge_with_class(args, 'bar') => { class: 'bar', id: 'thing' }
  #
  #   args = { class: 'foo', id: 'thing' }
  #   merge_with_class(args, 'bar') => { class: 'foo bar', id: thing }
  def merge_with_class(args, class_text)
    class_text = [class_text, args[:class]]
    class_text.compact!
    args.merge(class: class_text.join(' '))
  end

  def aria_describedby(*elements)
    elements.compact!
    return if elements.empty?

    %(aria-describedby="#{elements.join(' ')}")
  end
end

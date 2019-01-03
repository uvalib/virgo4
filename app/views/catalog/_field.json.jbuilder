# app/views/catalog/_field.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

doc_presenter ||= @presenter

json.set!(field_name) do
  json.id    "#{document_url}##{field_name}"
  json.label field.label
  json.value doc_presenter.field_value(field_name)
end

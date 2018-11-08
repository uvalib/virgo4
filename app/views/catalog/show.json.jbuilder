# app/views/catalog/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

json.links do
  json.self      full_url_for(url_for_document(@document))
  json.canonical full_url_for(url_for_document(@document, canonical: true))
end

json.data do
  type_field = blacklight_config.view_config(:show).display_type_field
  json.id   @document.id
  json.type @document[type_field]
  json.attributes do
    doc_presenter = json_presenter(@document)
    document_show_fields(@document).each do |field_name, field|
      if should_render_show_field?(@document, field)
        json.set! field_name, doc_presenter.field_value(field_name)
      end
    end
  end
end

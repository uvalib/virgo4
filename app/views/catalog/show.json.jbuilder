# app/views/catalog/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# If "&raw=true" is included in the URL parameter then the original search
# repository data will be included as the last portion of the result.

json.links do
  json.self      full_url_for(url_for_document(@document))
  json.canonical full_url_for(url_for_document(@document, canonical: true))
end

json.data do
  type_field = blacklight_config.view_config(:show).display_type_field
  json.id   @document.id
  json.type @document[type_field]
  json.attributes do
    @presenter.fields_to_render.each do |field_name, field|
      json.set! field_name, @presenter.field_value(field_name)
    end
  end
end

if params[:raw]
  if @document.respond_to?(:raw_source) && @document.raw_source.present?
    json.set! 'raw_data', @document.raw_source
  end
end

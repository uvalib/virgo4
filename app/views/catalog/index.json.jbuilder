# app/views/catalog/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

search    = search_state.to_h.merge(only_path: false)
canonical = search_action_url(search.except(:format).merge(canonical: true))

json.links do
  prev_page = @response.prev_page.to_s.presence
  next_page = @response.next_page.to_s.presence
  json.self      url_for(search)
  json.prev      url_for(search.merge(page: prev_page)) if prev_page
  json.next      url_for(search.merge(page: next_page)) if next_page
  json.last      url_for(search.merge(page: @response.total_pages))
  json.canonical url_for(canonical)
end

json.meta do
  json.pages @presenter.pagination_info
end

json.data do
  json.array!(@presenter.documents) do |doc|

    doc_url    = full_url_for(url_for_document(doc))
    type_field = blacklight_config.view_config(:index).display_type_field

    json.id   doc.id
    json.type doc[type_field]
    json.attributes do
      @presenter.fields_to_render.each do |field_name, field|
        json.partial! 'field',
          field:        field,
          field_name:   field_name,
          document_url: doc_url
      end
    end

    json.links do
      json.self doc_url
    end

  end
end

json.included do

  json.facets do
    json.array!(@presenter.search_facets) do |facet|
      name = facet.name
      json.id    name
      json.label facet_field_label(facet_configuration_for_field(name).key)
      json.items do
        json.array!(facet.items) do |item|
          value = item.value
          json.id
          json.label item.label unless item.label == value
          json.value value
          json.hits  item.hits
          json.links do
            if facet_in_params?(name, value)
              without_value = search_state.remove_facet_params(name, value)
              without_value[:only_path] = false
              json.remove search_action_path(without_value)
            else
              json.self path_for_facet(name, value, only_path: false)
            end
          end
        end
      end
      json.links do
        json.self search_facet_path(id: name, only_path: false)
      end
    end
  end

  json.search_fields do
    json.array!(search_fields) do |label, key|
      json.id    key
      json.label label
      json.links do
        json.self url_for(search.merge(search_field: key))
      end
    end
  end

  json.sort_fields do
    json.array!(active_sort_fields) do |key, field|
      json.id    key
      json.label field.label
      json.links do
        json.self url_for(search.merge(sort: key))
      end
    end
  end

end

# app/views/catalog/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

search = search_state.to_h.merge(only_path: false)

json.links do
  prev_page = @response.prev_page.to_s.presence
  next_page = @response.next_page.to_s.presence
  json.self url_for(search)
  json.prev url_for(search.merge(page: prev_page)) if prev_page
  json.next url_for(search.merge(page: next_page)) if next_page
  json.last url_for(search.merge(page: @response.total_pages))
end

json.meta do
  json.pages @presenter.pagination_info
end

json.data do
  json.array!(@presenter.documents) do |doc|
    doc_url = full_url_for(url_for_document(doc))
    json.id   doc.id
    json.type doc[blacklight_config.view_config(:index).display_type_field]
    json.attributes do
      doc_presenter = index_presenter(doc)
      index_fields(doc).each do |field_name, field|
        next unless should_render_index_field?(doc, field)
        json.set!(field_name) do
          json.id   "#{doc_url}##{field_name}"
          json.type 'document_value'
          json.attributes do
            json.value doc_presenter.field_value(field_name)
            json.label field.label
          end
        end
      end
    end
    json.links do
      json.self doc_url
    end
  end
end

json.included do
  json.array!(@presenter.search_facets) do |facet|
    json.type 'facet'
    json.id   facet.name
    json.attributes do
      facet_config = facet_configuration_for_field(facet.name)
      json.label facet_field_label(facet_config.key)
      json.items do
        json.array!(facet.items) do |item|
          json.id
          json.attributes do
            json.label item.label
            json.value item.value
            json.hits  item.hits
          end
          json.links do
            if facet_in_params?(facet.name, item.value)
              json.remove search_action_path(search_state.remove_facet_params(facet.name, item.value))
            else
              json.self path_for_facet(facet.name, item.value, only_path: false)
            end
          end
        end
      end
    end
    json.links do
      json.self search_facet_path(id: facet.name, only_path: false)
    end
  end

  json.array!(search_fields) do |(label, key)|
    json.type 'search_field'
    json.id   key
    json.attributes do
      json.label label
    end
    json.links do
      json.self url_for(search.merge(search_field: key))
    end
  end

  json.array!(active_sort_fields) do |key, field|
    json.type 'sort'
    json.id   key
    json.attributes do
      json.label field.label
    end
    json.links do
      json.self url_for(search.merge(sort: key))
    end
  end
end

# app/views/catalog/index.json.jbuilder

json.response do
  json.pages  @presenter.pagination_info
  json.docs   @presenter.documents
  json.facets @presenter.search_facets_as_json
end

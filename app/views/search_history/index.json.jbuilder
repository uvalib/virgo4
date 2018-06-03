# app/views/search_history/index.json.jbuilder

json.response do
  json.history @presenter.searches
end

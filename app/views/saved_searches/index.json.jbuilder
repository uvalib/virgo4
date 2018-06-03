# app/views/saved_searches/index.json.jbuilder

json.response do
  json.searches @presenter.searches
end

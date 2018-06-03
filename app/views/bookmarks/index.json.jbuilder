# app/views/bookmarks/index.json.jbuilder

json.response do
  json.bookmarks @presenter.bookmarks
end

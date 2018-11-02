# app/views/bookmarks/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

json.response do
  json.bookmarks @presenter.bookmarks
end

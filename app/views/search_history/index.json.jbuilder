# app/views/search_history/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

json.response do
  json.history @presenter.searches
end

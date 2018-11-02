# app/views/saved_searches/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true

json.response do
  json.searches @presenter.searches
end

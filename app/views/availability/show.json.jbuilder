# app/views/availability/show.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render availability details for a single document in JSON.

doc = document ||= @document
options ||= { format: :json }
index   ||= 0

doc_id = doc&.id || "unknown_#{index}"
status = doc&.availability_status || :none

template_opts = { document: doc, options: options }

json.availability do
  json.set!(doc_id) do
    json.status status.to_s.downcase
    json.partial!('availability/holdings', template_opts)
  end
end

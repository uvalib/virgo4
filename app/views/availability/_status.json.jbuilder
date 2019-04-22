# app/views/availability/_status.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render summary status for a single document in JSON.

doc = document ||= @document
index ||= 0

doc_id = doc&.id || "unknown_#{index}"
data   = doc&.availability_data || SolrDocument::AVAILABILITY_DATA_TEMPLATE

status    = data[:status]
locations = data[:locations]
error     = (status == :error)
missing   = locations.first&.last&.is_a?(String)
status    = status.to_s.downcase

json.set!(doc_id) do
  json.status(status)
  if error
    json.error(doc&.availability&.error_message || 'Unknown error')
  elsif missing
    json.unavailable do
      json.merge!(locations)
    end
  elsif locations.present?
    json.available do
      json.merge!(locations)
    end
  end
end

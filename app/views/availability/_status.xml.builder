# app/views/availability/_status.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render summary status for a single document in XML.

doc = document ||= @document
index ||= 0

doc_id = doc&.id || "unknown_#{index}"
data   = doc&.availability_data || SolrDocument::AVAILABILITY_DATA_TEMPLATE

status    = data[:status]
locations = data[:locations]
error     = (status == :error)
missing   = locations.first&.last&.is_a?(String)
status    = status.to_s.downcase

xml.document(id: doc_id) do
  xml.status status
  if error
    xml.error do
      xml.text!(doc&.availability&.error_message || 'Unknown error')
    end
  elsif missing
    xml.unavailable do
      locations.each_pair do |library, note|
        xml.library(name: library) do
          xml.location(name: 'missing') do
            xml.text! note
          end
        end
      end
    end
  elsif locations.present?
    xml.available do
      locations.each_pair do |library, location_counts|
        xml.library(name: library) do
          location_counts.each_pair do |name, location_count|
            xml.location(name: name) do
              location_count.each_pair do |key, value|
                xml.tag!(key, value)
              end
            end
          end
        end
      end
    end
  end
end

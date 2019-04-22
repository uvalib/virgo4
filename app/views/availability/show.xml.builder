# app/views/availability/show.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render availability details for a single document in XML.

doc = document ||= @document
options ||= { format: :xml }
index   ||= 0

doc_id = doc&.id || "unknown_#{index}"
status = doc&.availability_status || :none

template_opts = { document: doc, options: options }

xml.instruct! :xml, version: '1.0'
xml.availability do
  xml.document(id: doc_id) do
    xml.status status.to_s.downcase
    xml.indented! render('availability/holdings', template_opts)
  end
end

# app/views/availability/index.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render summary status for one or more documents in XML.

document ||= @document_list || @document
options  ||= { format: :xml }

docs     = Array.wrap(document)
base_opt = {}

xml.instruct! :xml, version: '1.0'
xml.availability do
  docs.each_with_index do |doc, idx|
    idx_options   = options.merge(index: idx)
    template_opts = base_opt.merge(document: doc, options: idx_options)
    xml.indented! render('availability/status', template_opts)
  end
end

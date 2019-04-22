# app/views/availability/index.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render summary status for one or more documents in JSON.

document ||= @document_list || @document
options  ||= { format: :json }

docs     = Array.wrap(document)
base_opt = {}

json.availability do
  docs.each_with_index do |doc, idx|
    idx_options   = options.merge(index: idx)
    template_opts = base_opt.merge(document: doc, options: idx_options)
    json.partial!('availability/status', template_opts)
  end
end

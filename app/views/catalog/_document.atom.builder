# app/views/catalog/_document.atom.builder
#
# frozen_string_literal: true
# warn_indent:           true

xml.entry do

  title = document_show_link_field(document)
  title &&= index_presenter(document).label(title)
  title ||= document.to_semantic_values[:title]&.first
  xml.title title

  # updated is required, for now we'll just set it to now, sorry
  xml.updated Time.current.iso8601

  link = full_url_for(url_for_document(document, lens: current_lens_key))
  xml.link rel: 'alternate', type: 'text/html', href: link

  # Add other doc-specific formats, Atom only lets us have one per
  # content type, so the first one in the list wins.
  xml << show_presenter(document).link_rel_alternates(unique: true)

  xml.id link

  author = document.to_semantic_values[:author]&.first
  xml.author { xml.name author } if author.present?

  type = 'html'
  with_format(type) do
    count = document_counter
    page  = render_document_partial(document, :index, document_counter: count)
    xml.summary(type: type) { xml.text! page }
  end

  # If they asked for a format, give it to them.
  format  = params['content_format']
  exports = format && document.export_formats[format.to_sym]
  if exports
    type = exports[:content_type]
    xml.content(type: type) do |content_element|
      # encode properly. See:
      # http://tools.ietf.org/html/rfc4287#section-4.1.3.3
      data = document.export_as(format)
      case type
        when /text\//     then content_element.text! data
        when /\+|\/xml$/i then content_element << data
        else                   content_element << Base64.encode64(data)
      end
    end
  end

end

# app/views/catalog/_document_default.atom.builder

title = document_show_link_field(document)
title &&= index_presenter(document).label(title)
title ||= document.to_semantic_values[:title]&.first

link = polymorphic_url(document, controller: current_lens_key)

author = document.to_semantic_values[:author]&.first&.presence

xml.entry do
  xml.title title

  # Updated is required, for now we'll just set it to now, sorry.
  xml.updated Time.current.iso8601

  xml.link 'rel' => 'alternate', 'type' => 'text/html', 'href' => link

  # Add other doc-specific formats, Atom only lets us have one per
  # content type, so the first one in the list wins.
  xml << show_presenter(document).link_rel_alternates(unique: true)

  xml.id link

  xml.author { xml.name(author) } if author

  with_format('html') do
    xml.summary 'type' => 'html' do
      xml.text! render_document_partial(document,
      :index,
      document_counter: document_counter)
    end
  end

  # If they asked for a format, give it to them.
  format = params['content_format']&.to_sym
  exports = format && document.export_formats[format]
  if exports

    type = exports[:content_type]

    xml.content type: type do |content_element|
      data = document.export_as(format)
      # Encode properly.
      # @see http://tools.ietf.org/html/rfc4287#section-4.1.3.3
      type = type.downcase
      if type =~ /\+|\/xml$/
        # XML - just put it right in.
        content_element << data
      elsif type =~ /text\//
        # Text - escape.
        content_element.text!(data)
      else
        # Something else - base64 encode it.
        content_element << Base64.encode64(data)
      end
    end

  end
end

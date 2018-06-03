# app/views/catalog/_document_default.rss.builder

title = document_show_link_field(document)
title &&= index_presenter(document).label(title)
title ||= document.to_semantic_values[:title]&.first

link = polymorphic_url(document, controller: current_lens_key)

author = document.to_semantic_values[:author]&.first&.presence

xml.item do
  xml.title(title)
  xml.link(link)
  xml.author(author) if author
end

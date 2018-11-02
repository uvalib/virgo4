# app/views/catalog/_document.rss.builder
#
# frozen_string_literal: true
# warn_indent:           true

xml.item do

  title = document_show_link_field(document)
  title &&= index_presenter(document).label(title)
  title ||= document.to_semantic_values[:title]&.first
  xml.title title

  link = full_url_for(url_for_document(document, lens: current_lens_key))
  xml.link link

  author = document.to_semantic_values[:author]&.first
  xml.author author if author.present?

end

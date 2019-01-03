# app/views/catalog/index.rss.builder
#
# frozen_string_literal: true
# warn_indent:           true

name      = application_name
lens      = current_lens_key.to_s
lens_name = "#{name} #{lens.capitalize}"

title =
  t('blacklight.search.page_title.title', application_name: name)
description =
  t('blacklight.search.page_title.title', application_name: lens_name)

partials = blacklight_config.view_config(:rss).partials

xml.instruct! :xml, version: '1.0'
xml.rss(version: '2.0') do
  xml.channel do
    xml.title       title
    xml.link        search_action_url(params.to_unsafe_h)
    xml.description description
    xml.language    'en-us'
    @document_list.each_with_index do |doc, index|
      html = render_document_partials(doc, partials, document_counter: index)
      xml << Nokogiri::XML.fragment(html)
    end
  end
end

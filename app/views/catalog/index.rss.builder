# app/views/catalog/index.rss.builder

name        = application_name
lens        = current_lens_key.to_s
lens_name   = "#{name} #{lens.capitalize}"
title       = t('blacklight.search.title', application_name: name)
description = t('blacklight.search.title', application_name: lens_name)
partials    = blacklight_config.view_config(:rss).partials

xml.instruct! :xml, version: '1.0'
xml.rss(version: '2.0') {
  xml.channel {
    xml.title       title
    xml.link        search_action_url(params.to_unsafe_h)
    xml.description description
    xml.language    'en-us'
    @document_list.each_with_index do |doc, idx|
      xml <<
        Nokogiri::XML.fragment(
          render_document_partials(doc, partials, document_counter: idx)
        )
    end
  }
}

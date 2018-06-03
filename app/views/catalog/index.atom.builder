# app/views/catalog/index.atom.builder

require 'base64'

name        = application_name
lens        = current_lens_key.to_s
title       = t('blacklight.search.title', application_name: name)

url_opt     = search_state.to_h.merge(only_path: false)

prev_page   = @response.prev_page.to_s.presence
next_page   = @response.next_page.to_s.presence
total_pages = @response.total_pages.to_s

opensearch  = opensearch_url(format: 'xml')

partials    = blacklight_config.view_config(:atom).partials

xml.instruct!(:xml, encoding: "UTF-8")

xml.feed('xmlns' => 'http://www.w3.org/2005/Atom',
         'xmlns:opensearch' => 'http://a9.com/-/spec/opensearch/1.1/') do

  xml.title   title
  # An author is required, so we'll just use the app name.
  xml.author  { xml.name application_name }

  xml.link    'rel' => 'self', 'href' => url_for(url_opt)
  xml.link    'rel' => 'alternate', 'href' => url_for(url_opt.merge(format: 'html')), 'type' => 'text/html'
  xml.id      url_for(url_opt.merge(format: 'html', content_format: nil, 'type' => 'text/html'))

  # Navigational and context links

  xml.link('rel' => 'next',     'href' => url_for(url_opt.merge(page: next_page))) if next_page
  xml.link('rel' => 'previous', 'href' => url_for(url_opt.merge(page: prev_page))) if prev_page
  xml.link('rel' => 'first',    'href' => url_for(url_opt.merge(page: 1)))
  xml.link('rel' => 'last',     'href' => url_for(url_opt.merge(page: total_pages)))

  # "search" doesn't seem to actually be legal, but is very common, and
  # used as an example in opensearch docs
  xml.link(
    'rel'  => 'search',
    'type' => 'application/opensearchdescription+xml',
    'href' => opensearch
  )

  # Opensearch response elements.
  xml.opensearch :totalResults, @response.total.to_s
  xml.opensearch :startIndex,   @response.start.to_s
  xml.opensearch :itemsPerPage, @response.limit_value
  xml.opensearch :Query, role: 'request', searchTerms: params[:q], startPage: @response.current_page

  # Updated is required, for now we'll just set it to now, sorry.
  xml.updated Time.current.iso8601

  @document_list.each_with_index do |doc, idx|
    xml <<
      Nokogiri::XML.fragment(
        render_document_partials(doc, partials, document_counter: idx)
      )
  end

end






# app/views/catalog/index.atom.builder
#
# frozen_string_literal: true
# warn_indent:           true

require 'base64'

xml.instruct!(:xml, encoding: 'UTF-8')

xml.feed('xmlns' => 'http://www.w3.org/2005/Atom',
         'xmlns:opensearch' => 'http://a9.com/-/spec/opensearch/1.1/') do

  # === Title
  title = t('blacklight.search.title', application_name: application_name)
  xml.title title

  # === Author
  # An author is required, so we'll just use the app name.
  xml.author { xml.name application_name }

  # === Links
  search = search_state.to_h.merge(only_path: false)
  xml.link rel: 'self', href: url_for(search)
  xml.link rel: 'alternate', href: url_for(search.merge(format: 'html')), type: 'text/html'
  xml.id   url_for(search.merge(format: 'html', content_format: nil, type: 'text/html'))

  # === Navigational and context links
  prev_page   = @response.prev_page.to_s.presence
  next_page   = @response.next_page.to_s.presence
  total_pages = @response.total_pages.to_s
  xml.link rel: 'next',     href: url_for(search.merge(page: next_page)) if next_page
  xml.link rel: 'previous', href: url_for(search.merge(page: prev_page)) if prev_page
  xml.link rel: 'first',    href: url_for(search.merge(page: 1))
  xml.link rel: 'last',     href: url_for(search.merge(page: total_pages))

  # "search" doesn't seem to actually be legal, but is very common, and
  # used as an example in opensearch docs
  xml.link(
    rel: 'search',
    type: 'application/opensearchdescription+xml',
    href: opensearch_url(format: 'xml')
  )

  # === Opensearch response elements
  xml.opensearch :totalResults, @response.total.to_s
  xml.opensearch :startIndex,   @response.start.to_s
  xml.opensearch :itemsPerPage, @response.limit_value
  xml.opensearch :Query,
    role: 'request', searchTerms: params[:q], startPage: @response.current_page

  # Updated is required, for now we'll just set it to now, sorry.
  xml.updated Time.current.iso8601

  # === Documents
  partials = blacklight_config.view_config(:atom).partials
  @document_list.each_with_index do |doc, index|
    html = render_document_partials(doc, partials, document_counter: index)
    xml << Nokogiri::XML.fragment(html)
  end

end

# app/views/catalog/index.atom.builder
#
# frozen_string_literal: true
# warn_indent:           true

require 'base64'

name = application_name

xml.instruct!(:xml, encoding: 'UTF-8')

xml.feed('xmlns' => 'http://www.w3.org/2005/Atom',
         'xmlns:opensearch' => 'http://a9.com/-/spec/opensearch/1.1/') do

  # === Title
  xml.title t('blacklight.search.page_title.title', application_name: name)

  # === Author
  # An author is required, so we'll just use the app name.
  xml.author { xml.name name }

  # === Links
  search    = search_state.to_h.merge(only_path: false)
  alternate = search.merge(format: 'html')
  id        = alternate.merge(content_format: nil, type: 'text/html')

  xml.link rel: 'self',      href: url_for(search)
  xml.link rel: 'alternate', href: url_for(alternate), type: 'text/html'
  xml.id   url_for(id)

  # === Navigational and context links
  next_page    = @response.next_page.to_s.presence
  next_page  &&= search.merge(page: next_page)
  prev_page    = @response.prev_page.to_s.presence
  prev_page  &&= search.merge(page: prev_page)
  first_page   = 1
  first_page &&= search.merge(page: first_page)
  last_page    = @response.total_pages.to_s.presence
  last_page  &&= search.merge(page: last_page)

  xml.link rel: 'next',     href: url_for(next_page)  if next_page
  xml.link rel: 'previous', href: url_for(page_page)  if prev_page
  xml.link rel: 'first',    href: url_for(first_page) if first_page
  xml.link rel: 'last',     href: url_for(last_page)  if last_page

  # "search" doesn't seem to actually be legal, but is very common, and
  # used as an example in opensearch docs
  xml.link(
    rel:  'search',
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

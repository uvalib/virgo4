# lib/ext/faraday/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Caching for items and search results from Solr and EBSCO EDS.
#
# == Implementation Notes
# Technically none of these are overrides -- they're new classes that happen to
# be defined in the 'Faraday' namespace.  This convention was picked up from
# the ebsco-eds gem; it's not clear whether it's either necessary or desirable.

__loading_begin(__FILE__)

require 'faraday'

# Load files from this subdirectory.
_LIB_EXT_FARADAY_LOADS ||=
  Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].each do |path|
    require(path) unless path == __FILE__
  end

Faraday::Middleware.register_middleware(
  eds_caching_middleware:    Faraday::EdsCachingMiddleware,
  solr_caching_middleware:   Faraday::SolrCachingMiddleware,
  solr_exception_middleware: Faraday::SolrExceptionMiddleware
)

__loading_end(__FILE__)

# lib/ext/faraday/solr_caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday'

module Faraday

  # Caching for items and search results from Solr.
  #
  # == Implementation Notes
  # Technically this isn't an override -- it's a new class that happens to be
  # defined in the 'Faraday' namespace.  This convention was picked up from
  # the ebsco-eds gem; it's not clear whether it's either necessary or
  # desirable.
  #
  class SolrCachingMiddleware < Faraday::Middleware

    include CachingMiddlewareConcern

    # Default expiration time.
    DEFAULT_EXPIRATION = 1.hour

    # Default options.
    #
    DEFAULT_OPTIONS = {
      http_header:     'x-faraday-solr-cache',
      cache_dir:       File.join(FARADAY_CACHE_DIR, 'solr'),
      expires_in:      DEFAULT_EXPIRATION,
      cacheable_paths: %w(
        /get?
        /select?
        /suggest?
      )
    }.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize
    #
    # @param [Faraday::Middleware] app
    # @param [Hash, nil]           opt
    #
    # @option opt [Logger]                              :logger
    # @option opt [String]                              :cache_dir
    # @option opt [Symbol, ActiveSupport::Cache::Store] :store
    # @option opt [Hash]                                :store_options
    # @option opt [ActiveSupport::Duration, Integer]    :expires_in
    #
    # @see RSolr::ClientExt#connection
    #
    # This method overrides:
    # @see Faraday::CachingMiddlewareConcern#initialize
    #
    def initialize(app, opt = nil)
      opt = DEFAULT_OPTIONS.deep_merge(opt || {})
      @store_options = opt[:store_options] || {}
      @expires_in    = opt[:expires_in] || @store_options[:expires_in]
      @store_options[:expires_in] = @expires_in
      super(app, opt)
    end

  end

end

__loading_end(__FILE__)

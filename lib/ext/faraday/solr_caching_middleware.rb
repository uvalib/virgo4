# lib/ext/faraday/solr_caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday'

module Faraday

  # Default values for Solr middleware.
  #
  module SolrCachingMiddlewareDefaults

    include CachingMiddlewareDefaults

    # Default options.
    #
    DEFAULT_OPTIONS =
      CachingMiddlewareDefaults::DEFAULT_OPTIONS.merge(
        namespace:       'solr',
        expires_in:      DEFAULT_EXPIRATION,
        cacheable_paths: %w(
          /get?
          /select?
          /suggest?
        )
      ).deep_freeze

  end

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
    include SolrCachingMiddlewareDefaults

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize an instance.
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

# lib/ext/faraday/eds_caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday/eds_caching_middleware'

module Faraday

  # Caching for items and search results from EBSCO EDS.
  #
  module EdsCachingMiddlewareExt

    include CachingMiddlewareConcern

    # Default expiration time.
    DEFAULT_EXPIRATION = 30.minutes

    # Lifetime of the auth token.
    AUTH_TOKEN_EXPIRATION = 30.minutes

    # Default options.
    #
    # @see EBSCO::EDS::ConfigurationExt#DEFAULT_CONFIG
    #
    DEFAULT_OPTIONS = {
      http_header:            'x-faraday-eds-cache',
      cache_dir:              File.join(FARADAY_CACHE_DIR, 'eds'),
      auth_expire:            (AUTH_TOKEN_EXPIRATION - 5.minutes),
      info_expire:            1.day,
      retrieve_expire:        DEFAULT_EXPIRATION,
      search_expire:          DEFAULT_EXPIRATION,
      export_format_expire:   1.day,
      citation_styles_expire: 1.day,
      cacheable_paths:        %w(
        /authservice/rest/uidauth
        /edsapi/rest/ExportFormat
        /edsapi/rest/CitationStyles
        /edsapi/rest/Info
        /edsapi/rest/Retrieve?
        /edsapi/rest/Search?
      )
    }.deep_freeze

    # Sanity check.
    unless DEFAULT_OPTIONS[:auth_expire] < AUTH_TOKEN_EXPIRATION
      raise 'auth_expire must be less than the auth token expiration'
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize
    #
    # @param [Faraday::Middleware] app
    # @param [Array]               args
    #
    # @option x [Logger]                              :logger
    # @option x [String]                              :cache_dir
    # @option x [Symbol, ActiveSupport::Cache::Store] :store
    # @option x [Hash]                                :store_options
    # @option x [ActiveSupport::Duration, Integer]    :auth_expire
    # @option x [ActiveSupport::Duration, Integer]    :info_expire
    # @option x [ActiveSupport::Duration, Integer]    :retrieve_expire
    # @option x [ActiveSupport::Duration, Integer]    :search_expire
    # @option x [ActiveSupport::Duration, Integer]    :export_format_expire
    # @option x [ActiveSupport::Duration, Integer]    :citation_styles_expire
    #
    # This method overrides:
    # @see Faraday::CachingMiddlewareConcern#initialize
    #
    def initialize(app, *args)
      opt = DEFAULT_OPTIONS.deep_merge(args.last || {})

      # auth_expire must be less than the 30 minute auth token expiration.
      @auth_expire = [opt[:auth_expire], DEFAULT_OPTIONS[:auth_expire]].min

      @info_expire            = opt[:info_expire]
      @retrieve_expire        = opt[:retrieve_expire]
      @search_expire          = opt[:search_expire]
      @export_format_expire   = opt[:export_format_expire]
      @citation_styles_expire = opt[:citation_styles_expire]

      super(app, opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Report the expiration based on the requested path.
    #
    # @param [Faraday::Env, nil] env
    #
    # @return [Numeric]
    #
    # This method overrides:
    # @see Faraday::CachingMiddlewareConcern#expiration
    #
    def expiration(env = nil)
      case request_url(env)
        when %r{/authservice/rest/uidauth}   then @auth_expire
        when %r{/edsapi/rest/Info}           then @info_expire
        when %r{/edsapi/rest/Search\?}       then @search_expire
        when %r{/edsapi/rest/Retrieve\?}     then @retrieve_expire
        when %r{/edsapi/rest/ExportFormat}   then @export_format_expire
        when %r{/edsapi/rest/CitationStyles} then @citation_styles_expire
      end || DEFAULT_EXPIRATION
    end

    # Indicate whether the given request is eligible for caching.
    #
    # @param [Faraday::Env] env
    #
    # This method overrides:
    # @see Faraday::CachingMiddlewareConcern#cacheable?
    #
    def cacheable?(env)
      return false unless super(env)
      return true  unless env&.body&.include?('"jump_request"')
      log("NON-CACHEABLE URI (jump_request): #{request_url(env)}")
      false
    end

  end

  # ===========================================================================
  # Override gem definitions
  # ===========================================================================

  override EdsCachingMiddleware => EdsCachingMiddlewareExt

end

__loading_end(__FILE__)

# lib/ext/faraday/eds_caching_middleware.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday/eds_caching_middleware'

module Faraday

  # Caching for items and search results from EBSCO EDS.
  #
  # This extends the ebsco-eds gem version of this class.
  #
  class EdsCachingMiddleware < Faraday::Middleware

    # Temporary directory that will hold the Faraday cache directory for
    # :file_store.
    CACHE_ROOT_DIR = ENV.fetch('TMPDIR', '/tmp').freeze

    # Faraday cache directory for :file_store.
    FARADAY_CACHE_DIR = File.join(CACHE_ROOT_DIR, 'faraday_eds_cache').freeze

    # Default expiration time.
    DEFAULT_EXPIRATION = 30.minutes

    # Lifetime of the auth token.
    AUTH_TOKEN_EXPIRATION = 30.minutes

    # Default options
    #
    DEFAULT_OPTIONS = {
      logger:                 nil,
      cache_dir:              FARADAY_CACHE_DIR,
      auth_expire:            (AUTH_TOKEN_EXPIRATION - 5.minutes),
      info_expire:            1.day,
      retrieve_expire:        DEFAULT_EXPIRATION,
      search_expire:          DEFAULT_EXPIRATION,
      export_format_expire:   1.day,
      citation_styles_expire: 1.day,
      http_header:            'x-faraday-eds-cache',
      store:                  :memory_store,
      store_options:          {},
      cacheable_paths: %w(
        /authservice/rest/uidauth
        /edsapi/rest/ExportFormat
        /edsapi/rest/CitationStyles
        /edsapi/rest/Info
        /edsapi/rest/Retrieve?
        /edsapi/rest/Search?
      ),
    }.freeze

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
    # @option args [Logger]                               :logger
    # @option args [String]                               :cache_dir
    # @option args [ActiveSupport::Duration, Integer]     :expires_in
    # @option args [Symbol, ActiveSupport::Cache::Store]  :store
    # @option args [Hash]                                 :store_options
    #
    def initialize(app, *args)

      @app = app
      opt = DEFAULT_OPTIONS
      opt = opt.merge(args.first) if args.first.is_a?(Hash)

      @logger                 = opt[:logger]
      @cache_dir              = opt[:cache_dir]
      @auth_expire            = opt[:auth_expire]
      @info_expire            = opt[:info_expire]
      @retrieve_expire        = opt[:retrieve_expire]
      @search_expire          = opt[:search_expire]
      @export_format_expire   = opt[:export_format_expire]
      @citation_styles_expire = opt[:citation_styles_expire]
      @http_header            = opt[:http_header]
      @store                  = opt[:store]
      @store_options          = opt[:store_options]
      @cacheable_paths        = opt[:cacheable_paths]

      # auth_expire must be less than the 30 minute auth token expiration.
      @auth_expire = [@auth_expire, DEFAULT_OPTIONS[:auth_expire]].min

      if @store == :file_store
        if !@cache_dir
          @cache_dir = FARADAY_CACHE_DIR
        elsif !@cache_dir.start_with?('/')
          @cache_dir = File.join(CACHE_ROOT_DIR, @cache_dir)
        end
      end

      initialize_store
    end

    # Generate cache key.
    #
    # @param [Faraday::Env] env
    #
    # @return [String, nil]
    #
    def key(env)
      request_url(env)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # request_url
    #
    # @param [Faraday::Env] env
    #
    # @return [String, nil]
    #
    def request_url(env)
      env&.url&.request_uri
    end

    # call!
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response, nil]
    #
    def call!(env)
      cache_key = key(env)
      if !cacheable?(env)
        @app.call(env)
      elsif complete?(env)
        log_status(env, cache_key, 'complete')
        to_response(env)
      elsif (response_env = read_cache(env, cache_key))
        to_response(response_env)
      else
        @app.call(env).on_complete do |response_env|
          if response_env
            response_env.response_headers[@http_header] = 'MISS'
            write_cache(response_env, cache_key)
          else
            log("request failed for #{cache_key}")
          end
        end
      end
    end

    # Indicate whether the given request is eligible for caching.
    #
    # @param [Faraday::Env] env
    #
    def cacheable?(env)
      if (url = request_url(env)).blank?
        log("NO URI for request #{env.inspect}")
      elsif @cacheable_paths&.none? { |path| url.include?(path) }
        log("NON-CACHEABLE URI: #{url}")
      elsif env&.body && env.body.include?('"jump_request"')
        log("NON-CACHEABLE URI (jump_request): #{url}")
      else
        true
      end
    end

    # Does the request/response indicate that it holds a completed response.
    #
    # @param [Faraday::Env] env
    #
    def complete?(env)
      hit_status(env).present?
    end

    # Show whether the request/response has been updated with a hit status.
    #
    # @param [Faraday::Env] env
    #
    # @return [String, nil]           Either 'HIT' or 'MISS' if present.
    #
    def hit_status(env)
      env&.response_headers&.dig(@http_header) ||
        env&.request_headers&.dig(@http_header)
    end

    # read_cache
    #
    # @param [Faraday::Env] env
    # @param [String, nil]  cache_key
    #
    # @return [Faraday::Env, nil]
    #
    # Used in place of:
    # @see Faraday::EdsCachingMiddleware#cached_response
    #
    def read_cache(env, cache_key = nil)
      return unless cache_key ||= key(env)
      @store.fetch(cache_key).tap do |response_env|
        response_env.response_headers[@http_header] = 'HIT' if response_env
        log_status(response_env, cache_key)
      end
    end

    # write_cache
    #
    # @param [Faraday::Env] env
    # @param [String, nil]  cache_key
    #
    # @return [TrueClass, FalseClass, nil]
    #
    # @see self#cache_opt
    #
    # Used in place of:
    # @see Faraday::EdsCachingMiddleware#cache_response
    #
    def write_cache(env, cache_key = nil)
      return unless (cache_key ||= key(env))
      @store.write(cache_key, env, cache_opt(env)).tap do |success|
        status = (' FAILED:' unless success)
        log("cache WRITE:#{status} #{cache_key}")
      end
    end

    # Generate options to override the default cache options set in the
    # initializer based on the nature of the request.
    #
    # @param [Faraday::Env] env
    #
    # @return [Hash]
    #
    # @see self#write_cache
    #
    def cache_opt(env)
      url = request_url(env)
      expiry =
        case url
          when %r{/authservice/rest/uidauth}   then @auth_expire
          when %r{/edsapi/rest/Info}           then @info_expire
          when %r{/edsapi/rest/Search\?}       then @search_expire
          when %r{/edsapi/rest/Retrieve\?}     then @retrieve_expire
          when %r{/edsapi/rest/ExportFormat}   then @export_format_expire
          when %r{/edsapi/rest/CitationStyles} then @citation_styles_expire
          else                                      DEFAULT_EXPIRATION
        end
      log("expires in #{expiry} for #{url}")
      { expires_in: expiry }
    end

    # to_response
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response]
    #
    def to_response(env)
      env = env.dup
      response = Faraday::Response.new
      response.finish(env) unless env.parallel?
      env.response = response
    end

    # log
    #
    # @param [String] message
    #
    # @return [nil]
    #
    def log(message)
      @logger&.info("Faraday #{message}")
      nil
    end

    # log_status
    #
    # @param [Faraday::Env] env
    # @param [String, nil]  cache_key
    # @param [String, nil]  note
    #
    # @return [nil]
    #
    def log_status(env, cache_key = nil, note = nil)
      status = (hit_status(env) == 'HIT') ? 'HIT: ' : 'MISS:'
      cache_key ||= key(env)
      note &&= " [#{note}]"
      log("cache #{status} #{cache_key}#{note}")
    end

    # initialize_store
    #
    # @param [Symbol, nil] store      Default: @store.
    #
    # @return [ActiveSupport::Cache::Store, nil]
    #
    def initialize_store(store = nil)
      store ||= @store
      case store
        when ActiveSupport::Cache::Store
          store
        when Symbol
          options = []
          options << @cache_dir if store == :file_store
          options << @store_options
          @store = ActiveSupport::Cache.lookup_store(store, *options)
        else
          raise "expected Symbol, got #{store.class} #{store.inspect}"
      end
    end

  end

end

__loading_end(__FILE__)

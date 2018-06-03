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

    # Temporary directory that will hold the Faraday cache directory for
    # :file_store.
    CACHE_ROOT_DIR = ENV.fetch('TMPDIR', '/tmp').freeze

    # Faraday cache directory for :file_store.
    FARADAY_CACHE_DIR =
      File.join(CACHE_ROOT_DIR, 'faraday_cache', 'solr').freeze

    # Default options
    #
    # == Development Notes
    # :expires_in     TODO: Final value should vary depending on context
    #
    DEFAULT_OPTIONS = {
      logger:           Rails.logger,
      cache_dir:        FARADAY_CACHE_DIR,
      expires_in:       1.hour,
      http_header:      'x-faraday-solr-cache',
      store:            :file_store,
      store_options:    {},
      cacheable_paths:  %w(
        /select?
        /suggest?
      ),
    }.freeze

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
      super(app)

      opt = DEFAULT_OPTIONS
      opt = opt.merge(args.first) if args.first.is_a?(Hash)

      @logger          = opt[:logger]
      @cache_dir       = opt[:cache_dir]
      @expires_in      = opt[:expires_in]
      @http_header     = opt[:http_header]
      @store           = opt[:store]
      @store_options   = opt[:store_options]
      @cacheable_paths = opt[:cacheable_paths]

      if @expires_in
        @store_options[:expires_in] ||= @expires_in
      else
        @expires_in = @store_options[:expires_in]
      end

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

    # call
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response, nil]
    #
    def call(env)
      dup.call!(env)
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
    def cache_opt(env)
      {}
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
      return store if store.is_a?(ActiveSupport::Cache::Store)
      unless store.is_a?(Symbol)
        raise "expected Symbol, got #{store.class} #{store.inspect}"
      end
      parameters = [store]
      parameters << @cache_dir if store == :file_store
      parameters << @store_options
      @store = ActiveSupport::Cache.lookup_store(*parameters)
    end

  end

end

__loading_end(__FILE__)

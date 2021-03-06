# lib/ext/faraday/concerns/caching_middleware_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/concern'
require 'faraday'

module Faraday

  # Common middleware default values.
  #
  module CachingMiddlewareDefaults

    # Base temporary directory.
    TMP_ROOT_DIR =
      ENV['TMPDIR']&.sub(/^([^\/])/, "#{Rails.root}/\\1")&.freeze || Dir.tmpdir

    # Directory for caching.
    CACHE_ROOT_DIR = File.join(TMP_ROOT_DIR, 'cache').freeze

    # Faraday cache directory for :file_store.
    FARADAY_CACHE_DIR = File.join(CACHE_ROOT_DIR, 'faraday').freeze

    # Redis server cache configuration.
    RAILS_CONFIG = Rails.application.config_for(:redis).deep_symbolize_keys

    # Default expiration time.
    DEFAULT_EXPIRATION = 1.hour

    # Default options appropriate for any including class.
    #
    DEFAULT_OPTIONS = {
      store:  :redis_cache_store,
      logger: Rails.logger,
    }.freeze

  end

  # A common implementation for locally-defined caching middleware.
  #
  # == Implementation Notes
  # This is patterned after the EdsCachingMiddleware class provided by the
  # ebsco-eds gem, but with 'cache_response'/'cached_response' replaced with
  # 'write_cache'/'read_cache'.
  #
  module CachingMiddlewareConcern

    extend ActiveSupport::Concern

    include CachingMiddlewareDefaults

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @return [Logger, nil]
    attr_reader :logger

    # @return [String]
    attr_reader :http_header

    # @return [ActiveSupport::Cache::Store]
    attr_reader :store

    # @return [Hash]
    attr_reader :store_options

    # @return [Array<String>]
    attr_reader :cacheable_paths

    # Initialize
    #
    # @param [Faraday::Middleware] app
    # @param [Hash, nil]           opt
    #
    # @option opt [Logger]                              :logger
    # @option opt [String]                              :cache_dir
    # @option opt [Symbol, ActiveSupport::Cache::Store] :store
    # @option opt [Hash]                                :store_options
    # @option opt [String]                              :http_header
    # @option opt [Array<String>]                       :cacheable_paths
    #
    # This method replaces:
    # @see Faraday::EdsCachingMiddleware#initialize
    #
    def initialize(app, opt = nil)
      @app = app
      opt  = DEFAULT_OPTIONS.deep_merge(opt || {})
      @namespace = opt[:namespace]
      raise 'including class must define :namespace' if @namespace.blank?
      @logger          = opt[:logger]
      @cache_dir       = opt[:cache_dir]
      @http_header     = opt[:http_header] || "x-faraday-#{@namespace}-cache"
      @store           = opt[:store]
      @store_options   = opt[:store_options]
      @cacheable_paths = Array.wrap(opt[:cacheable_paths]).presence
      initialize_logger
      initialize_store
    end

    # Generate cache key.
    #
    # @param [Faraday::Env] env
    #
    # @return [String, nil]
    #
    # This method replaces:
    # Faraday::EdsCachingMiddleware#key
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
    # This method replaces:
    # Faraday::EdsCachingMiddleware#call
    #
    def call(env)
      dup.call!(env)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Report the expiration based on the requested path.
    #
    # @param [Faraday::Env] env
    #
    # @return [Numeric]
    #
    def expiration(env = nil)
      DEFAULT_EXPIRATION
    end

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
    # This method replaces:
    # Faraday::EdsCachingMiddleware#call!
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
            response_env.response_headers[http_header] = 'MISS'
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
    # This method replaces:
    # Faraday::EdsCachingMiddleware#cacheable?
    #
    def cacheable?(env)
      result = false
      if (url = request_url(env)).blank?
        log("NO URI for request #{env.inspect}")
      elsif cacheable_paths&.none? { |path| url.include?(path) }
        log("NON-CACHEABLE URI: #{url}")
      else
        result = true
      end
      result
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
      env&.response_headers&.dig(http_header) ||
        env&.request_headers&.dig(http_header)
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
        response_env.response_headers[http_header] = 'HIT' if response_env
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
    # This method replaces:
    # Faraday::EdsCachingMiddleware#cache_opt
    #
    def cache_opt(env)
      { expires_in: expiration(env) }
    end

    # to_response
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response]
    #
    # This method replaces:
    # Faraday::EdsCachingMiddleware#to_response
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
      $stderr.puts("Faraday #{message}") # TODO: delete
      logger&.info("Faraday #{message}")
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

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Run from #initialize to set up the logger.
    #
    # @return [void]
    #
    def initialize_logger
      return if @logger.blank?
      log = @logger
      log = log.to_s if log.is_a?(Pathname)
      if log.is_a?(String)
        log = File.join(TMP_ROOT_DIR, log) unless log.start_with?('/')
        @logger =
          Logger.new(log).tap { |l| l.level = Logger.const_get(@log_level) }
      end
      unless @logger.is_a?(Logger)
        raise "expected String, got #{log.class} #{log.inspect}"
      end
    end

    # Run from #initialize to set up the cache store.
    #
    # @return [void]
    #
    # This method replaces:
    # Faraday::EdsCachingMiddleware#initialize_store
    #
    def initialize_store
      if (type = @store).is_a?(Symbol)
        params  = []
        options = @store_options&.dup || {}
        case type
          when :file_store
            @cache_dir ||= File.join(FARADAY_CACHE_DIR, @namespace)
            @cache_dir ||= FARADAY_CACHE_DIR
            params << @cache_dir
          when :redis_cache_store
            options.merge!(RAILS_CONFIG)
            options.merge!(namespace: @namespace)
        end
        params << options
        @store = ActiveSupport::Cache.lookup_store(type, *params)
      end
      unless @store.is_a?(ActiveSupport::Cache::Store)
        raise "expected Symbol, got #{@store.class} #{@store.inspect}"
      end
    end

  end

end

__loading_end(__FILE__)

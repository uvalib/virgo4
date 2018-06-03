# lib/ext/rsolr/client.rb

__loading_begin(__FILE__)

require 'rsolr/client'

# =============================================================================
# :section: Inject methods into RSolr::Client
# =============================================================================

override RSolr::Client do

  # Default RSolr options.
  DEFAULT_OPTIONS = {
    update_path:    'update',
    update_format:  RSolr::JSON::Generator,
    #
    # === Connection options
    #
    # url:          'http://127.0.0.1:8983/solr/'
    # proxy:        nil,
    # timeout:      3.seconds,
    # open_timeout: 2.seconds,
    #
    # @see Faraday::Connection#initialize
    # @see Faraday::ConnectionOptions#initialize
    #
    url:            'http://127.0.0.1:8983/solr/',
    conn_opt: {
      request: {
        timeout:        4.seconds,
        open_timeout:   3.seconds,
        params_encoder: Faraday::FlatParamsEncoder
      },
    },
    #
    # === Options for retry request
    #
    # retry_after_limit:  2
    # retry_503:          false
    #
    retry_opt: {
      max:                 3,
      interval:            0.05,
      interval_randomness: 0.5,
      backoff_factor:      2,
      exceptions:          %w(Faraday::Error Timeout::Error) # if :retry_503
    },
  }

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Initialize.
  #
  # @param [Faraday::Connection, nil] connection
  # @param [Hash, nil]                options
  #
  # == Implementation Notes
  # The default adapter (:net_http) has been replaced to see whether this
  # yields better performance.
  # @see https://engineering.wework.com/ruby-users-be-wary-of-net-http-f284747288b2
  #
  # (This is specified through 'http_adapter' in 'config/blacklight.yml' which
  # will be passed in through *options*.)
  #
  def initialize(connection, options = {})
    # Method parameters.
    @connection = connection
    options = DEFAULT_OPTIONS.deep_merge(options || {})

    # Update connection options.
    @conn_opt = options.delete(:conn_opt).dup
    @conn_opt[:request].merge!(options.slice(:timeout, :open_timeout))
    @uri = @proxy = nil
    unless (url = options[:url]).is_a?(FalseClass)
      url += '/' unless url.last == '/'
      @conn_opt[:url] = @uri = ::URI.parse(url)
      case (proxy_url = options[:proxy])
        when false
          @proxy = false # Used to avoid setting the proxy from the environment
        when String
          proxy_url += '/' unless proxy_url.last == '/'
          @conn_opt[:proxy] = @proxy = ::URI::parse(proxy_url)
      end
    end

    # Update retry options.
    @conn_retry_opt = options.delete(:retry_opt).dup
    if (max = options[:retry_after_limit])
      @conn_retry_opt[:max] = max
    end
    unless options[:retry_503]
      @conn_retry_opt.delete(:exceptions)
    end

    # Other options.
    @conn_adapter  = (options[:http_adapter] || Faraday.default_adapter).to_sym
    @update_path   = options[:update_path]
    @update_format = options.delete(:update_format)
    @options       = options
  end

  # connection
  #
  # @return [Faraday::Connection]
  #
  def connection(*)
    @connection ||=
      Faraday.new(@conn_opt) do |conn|
        conn.basic_auth(uri.user, uri.password) if uri.user && uri.password
        conn.use :solr_caching_middleware
        conn.use :solr_exception_middleware
        conn.request  :retry, @conn_retry_opt
        conn.response :raise_error
        conn.adapter  @conn_adapter
      end
  end

end

__loading_end(__FILE__)

# lib/ext/rsolr/lib/rsolr/client.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'rsolr/client'

# Override rsolr definitions.
#
# @see RSolr::Client
#
module RSolr::ClientExt

  # ===========================================================================
  # :section: RSolr::Client overrides
  # ===========================================================================

  public

  # Get a connection for making cached Solr requests.
  #
  # @return [Faraday::Connection]
  #
  # This method overrides:
  # @see RSolr::Client#connection
  #
  # @see Faraday::SolrCachingMiddleWare#initialize
  #
  def connection
    @connection ||=
      begin
        conn_opts = {}
        conn_opts[:url]     = uri.to_s
        conn_opts[:proxy]   = proxy if proxy
        conn_opts[:request] = options.slice(:timeout, :open_timeout)
        conn_opts[:request][:params_encoder] = Faraday::FlatParamsEncoder

        retry_opt = {
          max:                 options[:retry_after_limit],
          interval:            0.05,
          interval_randomness: 0.5,
          backoff_factor:      2,
        }
        if options[:retry_503]
          retry_opt[:exceptions] = %w(Faraday::Error Timeout::Error)
        end

        Faraday.new(conn_opts) do |conn|
          conn.basic_auth(uri.user, uri.password) if uri.user && uri.password
          conn.use :solr_caching_middleware
          conn.use :solr_exception_middleware
          conn.request  :retry, retry_opt
          conn.response :raise_error
          conn.adapter  options[:adapter] || Faraday.default_adapter
        end
      end
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override RSolr::Client => RSolr::ClientExt

__loading_end(__FILE__)

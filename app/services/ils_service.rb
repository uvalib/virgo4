# app/services/ils_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday'
require 'ils/common'
require 'ils/error'
require 'ils/schema'

require_subdir(__FILE__)

# Send/receive messages through the ILS Connector (a.k.a. Firehose).
#
class IlsService

  include Ils::Schema
  include Ils::Common

  BASE_URL =
    ENV['FIREHOSE_URL'] || 'http://firehose2.lib.virginia.edu:8081/firehose2'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [String]
  attr_reader :url

  # @return [Hash]
  attr_reader :options

  # @return [Faraday::Response, nil]
  attr_reader :response

  # @return [Exception, nil]
  attr_reader :exception

  # Initialize a new instance
  #
  # @param [Hash, nil] opt
  #
  # @option opt [String] :url         Base URL path to the external service
  #                                     (default: #BASE_URL).
  #
  def initialize(**opt)
    opt = opt.dup
    @url     = opt.delete(:url) || BASE_URL
    @options = opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get data from the ILS and update @response.
  #
  # @param [Array<String>] args       Path components to the ILS API; if the
  #                                     last is a Hash, it is passed as the
  #                                     options to the cache #fetch.
  #
  # @return [Faraday::Response]
  #
  def get_data(*args)
    params = args.last.is_a?(Hash) ? args.pop : {}
    action = args.join('/')
    @response = connection.get(action,  params)

  rescue => error
    Rails.logger.error { "ILS #{__method__}: #{error.message}" }
    @exception = error
    return nil # To be handled in the calling method.

  end

  # Post data to the ILS and update @response.
  #
  # @param [Array<String>] args       Path components to the ILS API; the last
  #                                     should be a Hash containing the data
  #                                     items to send.
  #
  # @return [Faraday::Response]
  #
  def post_data(*args)
    params = args.last.is_a?(Hash) ? args.pop : {}
    action = args.join('/')
    @response = connection.post(action, params.to_json)

  rescue SocketError, EOFError => error
    @exception = error
    raise error # Handled by ApplicationController

  rescue => error
    Rails.logger.error { "ILS #{__method__}: #{error.message}" }
    @exception = error
    raise error

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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
        conn_opts[:url]     = url
        #conn_opts[:proxy]   = proxy if proxy
        conn_opts[:request] = options.slice(:timeout, :open_timeout)
        conn_opts[:request][:params_encoder] = Faraday::FlatParamsEncoder

        retry_opt = {
          max:                 options[:retry_after_limit],
          interval:            0.05,
          interval_randomness: 0.5,
          backoff_factor:      2,
        }

        Faraday.new(conn_opts) do |conn|
          conn.use      :ils_caching_middleware
          conn.request  :retry, retry_opt
          conn.response :raise_error
          conn.adapter  options[:adapter] || Faraday.default_adapter
        end
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  # Include send and receive modules from "app/services/ils_service/*/*.rb".
  [Send, Recv].each do |base|
    base.constants(false).each do |name|
      mod = "#{base}::#{name}".constantize
      include mod if mod.is_a?(Module)
    end
  end

end

__loading_end(__FILE__)

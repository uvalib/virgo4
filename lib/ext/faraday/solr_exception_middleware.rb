# lib/ext/faraday/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'faraday'

module Faraday

  # Error handling for Solr results.
  #
  # == Implementation Notes
  # It's not clear whether this is a useful addition; RSolr may already handle
  # errors well enough on its own.
  #
  class SolrExceptionMiddleware < Faraday::Middleware

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # call
    #
    # @param [Faraday::Env] env
    #
    # @return [Faraday::Response, nil]
    #
    def call(env)
      @app.call(env).on_complete do |response|
        Log.debug {
          "#{self.class}: response status #{response.status.inspect}"
        }
      end

    rescue Faraday::ClientError => e
      Log.info { "#{self.class}: #{e.class} caught #{e}" }
      raise

    rescue Faraday::Error => e
      Log.info { "#{self.class}: #{e.class} caught #{e}" }
      raise RSolr::Error::Http.new(e.response)

    rescue Exception => e
      Log.info { "#{self.class}: Faraday caught #{e}" }
      raise

    end

  end

end

__loading_end(__FILE__)

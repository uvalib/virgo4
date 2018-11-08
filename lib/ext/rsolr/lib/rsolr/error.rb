# lib/ext/rsolr/lib/rsolr/error.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'rsolr/error'

# Override rsolr definitions.
#
# @see RSolr::Error::SolrContext
#
module RSolr::Error::SolrContextExt

  # ===========================================================================
  # :section: RSolr::Error::SolrContext overrides
  # ===========================================================================

  protected

  # parse_solr_error_response
  #
  # @param [String] body
  #
  # @return [String, nil]
  #
  # This method overrides
  # @see RSolr::Error::SolrContext#parse_solr_error_response
  #
  # == Implementation Notes
  # The current RSolr assumes that the return from Solr is in Ruby format.
  # This implementation is able to handle extracting the error message from
  # Solr in either Ruby or JSON format.
  #
  def parse_solr_error_response(body)
    body = body.join if body.is_a?(Array)
    case body
      when /<pre>(.*)<\/pre>/mi            then $1
      when /(["'])msg\1\s*(:|=>)\s*(.*)/mi then $3
      else                                      body
    end.to_s
      .split("\n").first(10).join("\n")
      .gsub('&gt;', '>').gsub('&lt;', '<')
  rescue
    nil
  end

end

# Override rsolr definitions.
#
# @see RSolr::Error::Http
#
module RSolr::Error::HttpExt

  include RSolr::Error::SolrContextExt

end

# =============================================================================
# Override gem definitions
# =============================================================================

override RSolr::Error::SolrContext => RSolr::Error::SolrContextExt
override RSolr::Error::Http        => RSolr::Error::HttpExt

__loading_end(__FILE__)

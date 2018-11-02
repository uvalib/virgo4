# lib/blacklight/eds/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'blacklight/lens/response'

# Blacklight::Eds::Response
#
# @see Blacklight::Lens::Response
#
class Blacklight::Eds::Response < Blacklight::Lens::Response

  require_relative 'response/facets'
  include Blacklight::Eds::Response::Facets

  # ===========================================================================
  # :section: Blacklight::Solr::Response overrides
  # ===========================================================================

  public

  # document_factory
  #
  # @return [Class] (Blacklight::Eds::DocumentFactory)
  #
  def document_factory
    blacklight_config&.document_factory || Blacklight::Eds::DocumentFactory
  end

end

__loading_end(__FILE__)

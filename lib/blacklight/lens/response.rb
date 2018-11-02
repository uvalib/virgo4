# lib/blacklight/lens/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight/solr/response'

# Blacklight::Lens::Response
#
# Derived from:
# @see Blacklight::Solr::Response
#
class Blacklight::Lens::Response < Blacklight::Solr::Response

  # ===========================================================================
  # :section: Blacklight::Solr::Response overrides
  # ===========================================================================

  public

  # document_factory
  #
  # @return [Class] (Blacklight::Lens::DocumentFactory)
  #
  def document_factory
    blacklight_config&.document_factory || Blacklight::Lens::DocumentFactory
  end

end

__loading_end(__FILE__)

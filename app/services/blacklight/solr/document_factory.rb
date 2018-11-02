# app/services/blacklight/solr/document_factory.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight/solr'
require_relative '../lens/document_factory'

module Blacklight::Solr

  # Blacklight::Solr::DocumentFactory
  #
  # Generates a SolrDocument of the appropriate type.
  #
  # @see Blacklight::Lens::DocumentFactory
  #
  class DocumentFactory < Blacklight::Lens::DocumentFactory

    # =========================================================================
    # :section: Blacklight::DocumentFactory overrides
    # =========================================================================

    public

    # Return the class for documents of the kind expected by the current lens.
    #
    # @param [Object] _data           Unused.
    # @param [Hash]   opt
    #
    # @return [Class] (SolrDocument)
    #
    # @option opt [Class] :document_model
    #
    # This method overrides:
    # @see Blacklight::Lens::DocumentFactory#document_model
    #
    def self.document_model(_data, opt)
      opt[:solr_document_model] || opt[:document_model] || SolrDocument
    end

  end

end

__loading_end(__FILE__)

# app/services/blacklight/eds/document_factory.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require_relative '../lens/document_factory'

module Blacklight::Eds

  # Blacklight::Eds::DocumentFactory
  #
  # Generates an EdsDocument of the appropriate type.
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
    # @option opt [Class] :document_model
    #
    # @return [Class] (EdsDocument)
    #
    # This method overrides:
    # @see Blacklight::Lens::DocumentFactory#document_model
    #
    def self.document_model(_data, opt)
      opt[:document_model] || EdsDocument
    end

  end

end

__loading_end(__FILE__)

# lib/blacklight/lens/search_state.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight/search_state'

module Blacklight::Lens

  # Redefine SearchState for lens-sensitivity.
  #
  # @see Blacklight::SearchState
  #
  class SearchState < Blacklight::SearchState

    include Blacklight::Lens

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Short-cut operations for accessing search parameters directly by allowing
    # them to be accessed as if the SearchState instance was a Hash.
    delegate :[], :key?, :keys, to: :to_hash

    # =========================================================================
    # :section: Blacklight::SearchState overrides
    # =========================================================================

    public

    # Extension point for downstream applications to provide more interesting
    # routing to documents.
    #
    # @param [Blacklight::Document] doc
    # @param [Hash, nil]            opt
    #
    # @option opt [Symbol]  :lens       Return the URL as from another lens.
    # @option opt [Boolean] :canonical  Return the canonical URL.
    #
    # @return [Hash, Blacklight::Document]
    #
    # This method overrides:
    # @see Blacklight::SearchState#url_for_document
    #
    def url_for_document(doc, opt = nil)
      opt   = opt ? opt.dup : {}
      canon = opt.delete(:canonical)
      lens  = opt.delete(:lens)
      lens  = Blacklight::Lens.canonical_for(lens || doc) if canon
      if !lens && !doc.is_a?(Blacklight::Document)
        doc
      elsif !lens && (rte = blacklight_config_for(doc).show.route).is_a?(Hash)
        rte = rte.merge(action: :show, id: doc.id).merge(opt)
        rte[:controller] = params[:controller] if rte[:controller] == :current
        rte
      else
        lens ||= lens_key_for(doc)
        { controller: lens, action: :show, id: doc.id }.merge(opt)
      end
    end

  end

end

__loading_end(__FILE__)

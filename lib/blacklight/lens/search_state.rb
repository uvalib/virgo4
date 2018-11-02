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
    # @option options [Symbol] :lens
    #
    # @return [Hash, Blacklight::Document]
    #
    # This method overrides:
    # @see Blacklight::SearchState#url_for_document
    #
    def url_for_document(doc, opt = nil)
      opt = opt ? opt.dup : {}
      lens  = opt.delete(:lens)
      route = doc.is_a?(Blacklight::Document)
      route &&= blacklight_config_for(doc).show.route
      if route.is_a?(Hash)
        route = route.merge(action: :show, id: doc.id).merge(opt)
        current = (route[:controller] == :current)
        route[:controller] = params[:controller] if current
        route
      elsif lens || doc.is_a?(Blacklight::Document)
        lens ||= doc.lens          if doc.is_a?(Blacklight::Lens::Document)
        lens ||= lens_key_for(doc) if doc.is_a?(Blacklight::Document)
        { controller: lens, action: :show, id: doc.id }.merge(opt)
      else
        doc
      end
    end

  end

end

__loading_end(__FILE__)

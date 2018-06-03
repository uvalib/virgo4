# lib/blacklight/search_state_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'

module Blacklight

  # Overrides Blacklight::SearchState for lens-sensitivity.
  #
  # @see Blacklight::SearchState
  #
  class SearchStateExt < Blacklight::SearchState

    include LensHelper

    # =========================================================================
    # :section: Blacklight::SearchState replacements
    # =========================================================================

    public

    # TODO: This should avoid needing to do SearchStateExt.new.to_hash to
    # extract search parameter values.
    delegate :[], :key?, :keys, to: :to_hash

    # Extension point for downstream applications to provide more interesting
    # routing to documents.
    #
    # @param [Blacklight::Document] doc
    # @param [Hash, nil]            options
    #
    # @return [String, Blacklight::Document, nil]
    #
    # This method overrides:
    # @see Blacklight::SearchState#url_for_document
    #
    def url_for_document(doc, options = nil)
      valid = doc.is_a?(Blacklight::Document)
      valid ||=
        doc.respond_to?(:to_model) && doc.to_model.is_a?(Blacklight::Document)
      if !valid
        doc
      elsif (route = blacklight_config.show.route).is_a?(String)
        url_for([route, id: doc])
      else
        options ||= {}
        lens = options.delete(:lens) || current_lens_key
        path = options.reverse_merge(controller: lens, action: 'show', id: doc)
        path.merge!(route) if route.is_a?(Hash)
        path[:controller] = nil if path[:controller] == :current
        path[:controller] ||= params[:controller]
        path
      end
    end

  end

end

__loading_end(__FILE__)

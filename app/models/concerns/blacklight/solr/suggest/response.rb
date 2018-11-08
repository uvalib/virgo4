# app/models/concerns/blacklight/solr/suggest/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/solr'
require_relative '../../lens/suggest/response'

module Blacklight::Solr

  module Suggest

    # Blacklight::Solr::Suggest::Response
    #
    # @see Blacklight::Lens::Suggest::Response
    #
    class Response < Blacklight::Lens::Suggest::Response

      # =======================================================================
      # :section: Blacklight::Suggest::Response overrides
      # =======================================================================

      public

      # Tries the suggester response to return suggestions if they are present.
      #
      # @return [Array<Hash{String=>String}>]
      #
      # This method overrides:
      # @see Blacklight::Suggest::Response#suggestions
      #
      def suggestions
        query = request_params[:q] || request_params[:'suggest.q']
        response.dig(suggest_path, suggester_name, query, 'suggestions') || []
      end

    end

  end

end

__loading_end(__FILE__)

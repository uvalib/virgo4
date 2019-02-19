# app/models/concerns/blacklight/lens/suggest/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  module Suggest

    # Blacklight::Lens::Suggest::Response
    #
    # @see Blacklight::Suggest::Response
    #
    class Response < Blacklight::Suggest::Response

      # =======================================================================
      # :section: Blacklight::Suggest::Response overrides
      # =======================================================================

      public

      # Create a suggest response.
      #
      # @param [RSolr::HashWithResponse, nil] response
      # @param [Hash, nil]                    request_params
      # @param [String, nil]                  suggest_path
      # @param [String, nil]                  suggester_name
      #
      # This method overrides:
      # @see Blacklight::Suggest::Response#initialize
      #
      def initialize(
        response       = {},
        request_params = {},
        suggest_path   = '',
        suggester_name = ''
      )
        @response       = response
        @request_params = request_params
        @suggest_path   = suggest_path
        @suggester_name = suggester_name
      end

    end

  end

end

__loading_end(__FILE__)

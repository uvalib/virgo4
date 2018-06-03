# app/controllers/concerns/blacklight/suggest_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Replacement for Blacklight::Suggest
  #
  # @see Blacklight::Suggest
  #
  # == Implementation Notes
  # This does not include Blacklight::Suggest to avoid executing its `included`
  # block -- which means that it has to completely recreate the module.
  #
  module SuggestExt

    extend ActiveSupport::Concern

    # Needed for RubyMine to indicate overrides.
    include Blacklight::Suggest unless ONLY_FOR_DOCUMENTATION

    # Code to be added to the controller class including this module.
    included do |base|

      __included(base, 'Blacklight::SuggestExt')

      include SuggestHelper
      include Blacklight::SearchHelperExt
      include LensConcern

    end

    # =========================================================================
    # :section: Blacklight::Suggest replacements
    # =========================================================================

    public

    # == GET /catalog/suggest
    # == GET /:lens/suggest
    #
    # This method replaces:
    # @see Blacklight::Suggest#index
    #
    def index
      respond_to do |format|
        format.json { render json: suggestions_service.suggestions }
      end
    end

    # =========================================================================
    # :section: Blacklight::Suggest replacements
    # =========================================================================

    protected

    # suggestions_service
    #
    # @return [Blacklight::Suggest::Response]
    #
    # This method replaces:
    # @see Blacklight::Suggest#suggestions_service
    #
    def suggestions_service
      Blacklight::SuggestSearchExt.new(params, repository).suggestions
    end

  end

end

__loading_end(__FILE__)

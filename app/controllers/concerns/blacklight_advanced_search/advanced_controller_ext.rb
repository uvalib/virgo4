# app/controllers/concerns/blacklight_advanced_search/advanced_controller_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Common methods for the lens-specific replacements of AdvancedController.
#
# @see BlacklightAdvancedSearch::AdvancedController
#
module BlacklightAdvancedSearch::AdvancedControllerExt

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'BlacklightAdvancedSearch::AdvancedControllerExt')

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # Ensure that 'advanced' is searched first for view templates.
    #
    # @return [Array<String>]
    #
    # This method overrides:
    # @see ActionView::ViewPaths::ClassMethods#local_prefixes
    #
    def self.local_prefixes
      super.unshift('advanced').uniq
    end

  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedController replacements
  # ===========================================================================

  public

  # == GET /catalog/advanced
  # == GET /:lens/advanced
  #
  # TODO: Do a clean search to get total facet values THEN render to check boxes
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::AdvancedController#index
  #
  def index
    @response = get_advanced_search_facets unless request.method == :post
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedController replacements
  # ===========================================================================

  protected

  # get_advanced_search_facets
  #
  # We want to find the facets available for the current search, but:
  # * IGNORING current query
  #     (add in :facets_for_advanced_search_form filter)
  # * IGNORING current advanced search facets
  #     (remove :add_advanced_search_to_solr filter)
  #
  # @return [Blacklight::Solr::Response]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::AdvancedController#get_advanced_search_facets
  #
  def get_advanced_search_facets
    response, _ =
      search_results(params) do |search_builder|
        search_builder
          .except(:add_advanced_search_to_solr)
          .append(:facets_for_advanced_search_form)
      end
    response
  end

end

__loading_end(__FILE__)

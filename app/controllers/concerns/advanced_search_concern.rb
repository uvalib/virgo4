# app/controllers/concerns/advanced_search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AdvancedSearchConcern
#
# @see BlacklightAdvancedSearch::Controller
#
module AdvancedSearchConcern

  extend ActiveSupport::Concern

  include Blacklight::Lens::Controller
  include Blacklight::Lens::Catalog
  include SearchHistoryConstraintsHelper

  included do |base|

    __included(base, 'AdvancedSearchConcern')

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
  # :section: BlacklightAdvancedSearch::AdvancedController overrides
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
    @response = get_advanced_search_facets unless request.post?
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedController overrides
  # ===========================================================================

  protected

  # Overrides the Blacklight::Controller provided #search_action_url.
  #
  # By default, any search action from a Blacklight::Catalog controller should
  # use the current controller when constructing the route.
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::AdvancedController#search_action_url
  #
  def search_action_url(options = nil)
    opt = { controller: current_lens_key, action: 'index' }
    opt.reverse_merge!(options) if options.is_a?(Hash)
    url_for(opt)
  end

  # get_advanced_search_facets
  #
  # @return [Blacklight::Lens::Response]
  #
  # @see BlacklightAdvancedSearch::AdvancedController#get_advanced_search_facets
  #
  # NOTE: Added for blacklight_advanced_search
  # TODO: Re-evaluate after the gem is compatible with Blacklight 7
  #
  def get_advanced_search_facets
    response, _ =
      search_service.search_results do |search_builder|
        search_builder
          .except(:add_advanced_search_to_solr)
          .append(:facets_for_advanced_search_form)
      end
    response
  end

end

__loading_end(__FILE__)

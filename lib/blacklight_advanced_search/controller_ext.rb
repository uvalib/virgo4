# lib/blacklight_advanced_search/controller_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/parsing_nesting_parser'

# This module gets included into CatalogController, or another SearchHelper
# includer, to add advanced search behavior.
#
# @see BlacklightAdvancedSearch::Controller
#
module BlacklightAdvancedSearch::ControllerExt

  extend ActiveSupport::Concern

  # Needed for RubyMine to indicate overrides.
  include BlacklightAdvancedSearch::Controller unless ONLY_FOR_DOCUMENTATION

  include BlacklightAdvancedSearch::RenderConstraintsOverrideExt
  include BlacklightAdvancedSearch::CatalogHelperOverrideExt

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'BlacklightAdvancedSearch::ControllerExt')

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    # Display advanced search constraints properly.
    helper BlacklightAdvancedSearch::RenderConstraintsOverrideExt
    helper BlacklightAdvancedSearch::CatalogHelperOverrideExt

    helper_method :is_advanced_search?, :advanced_query
    helper_method :has_search_parameters?, :has_query?

  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::Controller replacements
  # ===========================================================================

  public

  # is_advanced_search?
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::Controller#is_advanced_search?
  #
  def is_advanced_search?(req_params = nil)
    req_params ||= params
    req_params[:f_inclusive].present? || advanced_search_key?(req_params)
  end

  # advanced_query
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [BlacklightAdvancedSearch::QueryParserExt, nil]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::Controller#advanced_query
  #
  def advanced_query(req_params = nil)
    req_params ||= params
    return unless is_advanced_search?(req_params)
    BlacklightAdvancedSearch::QueryParserExt.new(req_params, blacklight_config)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # has_query?
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # During operation this method overrides:
  # @see Blacklight::CatalogExt#has_search_parameters?
  #
  def has_search_parameters?(req_params = nil)
    req_params ||= params
    %i(q f f_inclusive search_field).any? { |f| req_params[f].present? }
  end

  # Indicate whether there has been a query issued by the user.
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # During operation this method overrides:
  # @see Blacklight::CatalogExt#has_query?
  #
  def has_query?(req_params = nil)
    req_params ||= params
    if advanced_search_key?(req_params)
      blacklight_config.search_fields.keys.any? { |f| req_params[f].present? }
    else
      req_params[:q].present? && (req_params[:q] != '*')
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether "search_field=advanced" is in the URL parameters.
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  def advanced_search_key?(req_params = nil)
    req_params ||= params
    req_params[:search_field] == blacklight_config.advanced_search[:url_key]
  end

end

__loading_end(__FILE__)

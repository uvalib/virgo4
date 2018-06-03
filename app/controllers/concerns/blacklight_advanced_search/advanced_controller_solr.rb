# app/controllers/concerns/blacklight_advanced_search/solr/advanced_controller_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# This sub-classes CatalogController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets.
#
# @see BlacklightAdvancedSearch::AdvancedControllerExt
#
# Used in place of:
# @see BlacklightAdvancedSearch::AdvancedController
#
class BlacklightAdvancedSearch::AdvancedControllerSolr < CatalogController
  include BlacklightAdvancedSearch::AdvancedControllerExt
end

__loading_end(__FILE__)

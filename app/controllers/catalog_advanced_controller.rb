# app/controllers/catalog_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/advanced_controller_solr'

# Overrides the Blacklight Advanced Search class of the same name.
#
# Compare with:
# @see AdvancedController
#
class CatalogAdvancedController < BlacklightAdvancedSearch::AdvancedControllerSolr
  include CatalogConcern
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

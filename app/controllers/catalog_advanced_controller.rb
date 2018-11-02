# app/controllers/catalog_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Overrides the Blacklight Advanced Search class of the same name.
#
# @see BlacklightAdvancedSearch::AdvancedController
#
class CatalogAdvancedController < BlacklightAdvancedSearch::AdvancedController
  include AdvancedSearchConcern
  include CatalogConcern
  include LensConcern
end

__loading_end(__FILE__)

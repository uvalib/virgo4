# app/controllers/concerns/blacklight_advanced_search/advanced_controller_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# This sub-classes ArticlesController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets.
#
# @see BlacklightAdvancedSearch::AdvancedControllerExt
#
# Used in place of:
# @see BlacklightAdvancedSearch::AdvancedController
#
class BlacklightAdvancedSearch::AdvancedControllerEds < ArticlesController
  include BlacklightAdvancedSearch::AdvancedControllerExt
end

__loading_end(__FILE__)

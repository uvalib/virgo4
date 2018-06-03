# app/controllers/advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Overrides the Blacklight Advanced Search class of the same name.
#
# The gem wants to see an AdvancedController.
#
class AdvancedController < BlacklightAdvancedSearch::AdvancedController
  include CatalogConcern
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

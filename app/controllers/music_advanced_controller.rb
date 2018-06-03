# app/controllers/music_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/advanced_controller_solr'

# AdvancedController variant for music search.
#
# Compare with:
# @see CatalogAdvancedController
#
class MusicAdvancedController < BlacklightAdvancedSearch::AdvancedControllerSolr
  include MusicConcern
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

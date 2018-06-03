# app/controllers/video_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/advanced_controller_solr'

# AdvancedController variant for video search.
#
# Compare with:
# @see CatalogAdvancedController
#
class VideoAdvancedController < BlacklightAdvancedSearch::AdvancedControllerSolr
  include VideoConcern
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

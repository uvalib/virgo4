# app/controllers/video_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AdvancedController variant for video search.
#
# Compare with:
# @see CatalogAdvancedController
#
class VideoAdvancedController < BlacklightAdvancedSearch::AdvancedController
  include AdvancedSearchConcern
  include VideoConcern
  include LensConcern
end

__loading_end(__FILE__)

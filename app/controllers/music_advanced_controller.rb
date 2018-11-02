# app/controllers/music_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AdvancedController variant for music search.
#
# Compare with:
# @see CatalogAdvancedController
#
class MusicAdvancedController < BlacklightAdvancedSearch::AdvancedController
  include AdvancedSearchConcern
  include MusicConcern
  include LensConcern
end

__loading_end(__FILE__)

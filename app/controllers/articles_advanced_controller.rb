# app/controllers/articles_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'blacklight_advanced_search/advanced_controller_eds'

# AdvancedController variant for articles.
#
# Compare with:
# @see CatalogAdvancedController
#
class ArticlesAdvancedController < BlacklightAdvancedSearch::AdvancedControllerEds
  include ArticlesConcern
  include Blacklight::Eds::CatalogEds
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

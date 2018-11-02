# app/controllers/articles_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AdvancedController variant for articles.
#
# Compare with:
# @see CatalogAdvancedController
#
class ArticlesAdvancedController < BlacklightAdvancedSearch::AdvancedController
  include AdvancedSearchConcern
  include ArticlesConcern
  include LensConcern
end

__loading_end(__FILE__)

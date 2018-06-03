# app/controllers/articles_controller.rb
#
# encoding:              utf-8
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'blacklight/eds/catalog_eds'

# CatalogController variant for articles.
#
# Compare with:
# @see CatalogController
#
class ArticlesController < ApplicationController
  include ArticlesConcern
  include Blacklight::Eds::CatalogEds
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

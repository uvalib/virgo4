# app/controllers/articles_controller.rb
#
# encoding:              utf-8
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Access articles via EBSCO EDS.
#
# Compare with:
# @see CatalogController
#
class ArticlesController < ApplicationController

  include ArticlesConcern
  include LensConcern

  self.blacklight_config = ::Config::Articles.new(self).blacklight_config

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  protected

  # The default controller for searches.
  #
  # @return [Class]
  #
  def default_catalog_controller
    self
  end

end

__loading_end(__FILE__)

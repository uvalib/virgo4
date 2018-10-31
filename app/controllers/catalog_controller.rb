# app/controllers/catalog_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Access index items via Solr.
#
# Compare with:
# @see CatalogController
#
class CatalogController < ApplicationController

  include CatalogConcern
  include LensConcern

  self.blacklight_config = ::Config::Catalog.new(self).blacklight_config

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

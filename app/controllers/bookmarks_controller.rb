# app/controllers/bookmarks_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookmarksController
#
# @see BookmarksConcern
#
class BookmarksController < CatalogController

  include BookmarksConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize controller instance and set the Blacklight configuration from
  # the class.
  #
  def initialize
    @blacklight_config = self.class.blacklight_config
  end

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  protected

  # The default controller for searches.
  #
  # @return [Class]
  #
  def default_catalog_controller
    CatalogController
  end

end

__loading_end(__FILE__)

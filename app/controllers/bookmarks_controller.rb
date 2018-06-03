# app/controllers/bookmarks_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'concerns/blacklight/bookmarks_ext'

# Replaces the Blacklight class of the same name for Blacklight::Document
# support.
#
class BookmarksController < ApplicationController

  include Blacklight::BookmarksExt
  include BlacklightAdvancedSearch::ControllerExt
  include LensConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Special handling to avoid LensConcern in this one case.
  #
  def initialize
    @blacklight_config = self.class.blacklight_config
    super
  end

end

__loading_end(__FILE__)

# app/helpers/bookmarks_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# BookmarksHelper
#
# @see Blacklight::BookmarksBehavior
#
module BookmarksHelper

  include BlacklightHelper

  def self.included(base)
    __included(base, '[BookmarksHelper]')
  end

  # TODO: ???

end

__loading_end(__FILE__)

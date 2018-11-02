# app/helpers/music_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# MusicHelper
#
# @see CatalogHelper
#
module MusicHelper

  include CatalogHelper

  def self.included(base)
    __included(base, '[MusicHelper]')
  end

  # TODO: ???

end

__loading_end(__FILE__)

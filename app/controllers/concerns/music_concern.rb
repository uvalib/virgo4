# app/controllers/concerns/music_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/music'

# MusicConcern
#
module MusicConcern

  extend ActiveSupport::Concern

  include CatalogConcern

  included do |base|
    __included(base, 'MusicConcern')
  end

end

__loading_end(__FILE__)

# app/controllers/concerns/video_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/video'

# VideoConcern
#
module VideoConcern

  extend ActiveSupport::Concern

  include CatalogConcern

  included do |base|
    __included(base, 'VideoConcern')
  end

end

__loading_end(__FILE__)

# app/helpers/video_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# VideoHelper
#
# @see CatalogHelper
#
module VideoHelper

  include CatalogHelper

  def self.included(base)
    __included(base, '[VideoHelper]')
  end

  # TODO: ???

end

__loading_end(__FILE__)

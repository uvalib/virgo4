# app/controllers/video_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller for the Video Lens.
#
class VideoController < ApplicationController

  include VideoConcern
  include LensConcern

  self.blacklight_config = ::Config::Video.new(self).blacklight_config

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  public

  # The default controller for searches.
  #
  # @return [Class]
  #
  def default_catalog_controller
    self
  end

end

__loading_end(__FILE__)

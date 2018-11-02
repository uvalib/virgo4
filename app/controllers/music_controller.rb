# app/controllers/music_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller for the Music Lens.
#
class MusicController < ApplicationController

  include MusicConcern
  include LensConcern

  self.blacklight_config = ::Config::Music.new(self).blacklight_config

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

# app/controllers/music_suggest_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Analogue of SuggestController for music search.
#
class MusicSuggestController < ApplicationController

  include MusicConcern
  include Blacklight::SuggestExt
  include BlacklightAdvancedSearch::ControllerExt

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

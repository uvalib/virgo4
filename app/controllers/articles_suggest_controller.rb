# app/controllers/articles_suggest_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'concerns/blacklight/eds/suggest_eds'

# Analogue of SuggestController for articles.
#
class ArticlesSuggestController < ApplicationController

  include ArticlesConcern
  include Blacklight::Eds::SuggestEds
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

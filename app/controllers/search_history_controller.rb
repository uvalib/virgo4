# app/controllers/search_history_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight class of the same name.
#
class SearchHistoryController < ApplicationController

  include Blacklight::Lens::Controller
  include SearchHistoryConcern
  include LensConcern

  helper BlacklightAdvancedSearch::RenderConstraintsOverride

end

__loading_end(__FILE__)

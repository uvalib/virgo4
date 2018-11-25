# app/controllers/saved_searches_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight class of the same name.
#
class SavedSearchesController < ApplicationController

  include Blacklight::Lens::Controller
  include SavedSearchesConcern
  include LensConcern

  helper BlacklightAdvancedSearch::RenderConstraintsOverride

end

__loading_end(__FILE__)

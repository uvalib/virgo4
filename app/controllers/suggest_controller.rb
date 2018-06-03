# app/controllers/suggest_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight class of the same name.
#
class SuggestController < ApplicationController
  include CatalogConcern
  include Blacklight::SuggestExt
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

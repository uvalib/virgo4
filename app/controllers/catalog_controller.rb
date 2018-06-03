# app/controllers/catalog_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight class of the same name.
#
class CatalogController < ApplicationController
  include CatalogConcern
  include Blacklight::CatalogExt
  include BlacklightAdvancedSearch::ControllerExt
end

__loading_end(__FILE__)

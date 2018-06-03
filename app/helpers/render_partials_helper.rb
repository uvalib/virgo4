# app/helpers/render_partials_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# This module should exist according to Blacklight::BlacklightHelperBehavior.
#
module RenderPartialsHelper
  include Blacklight::RenderPartialsHelper
end

__loading_end(__FILE__)

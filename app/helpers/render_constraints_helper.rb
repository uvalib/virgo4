# app/helpers/render_constraints_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight module with local behavior definitions.
#
module RenderConstraintsHelper
  include Blacklight::RenderConstraintsHelperBehaviorExt
end

__loading_end(__FILE__)

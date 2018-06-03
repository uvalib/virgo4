# app/helpers/component_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight module with local behavior definitions.
#
module ComponentHelper
  include Blacklight::ComponentHelperBehaviorExt
end

__loading_end(__FILE__)

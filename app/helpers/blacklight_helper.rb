# app/helpers/blacklight_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight module with local behavior definitions.
#
module BlacklightHelper
  include Blacklight::BlacklightHelperBehaviorExt
end

__loading_end(__FILE__)

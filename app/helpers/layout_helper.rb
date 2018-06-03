# app/helpers/layout_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Replaces the Blacklight module with local behavior definitions.
#
module LayoutHelper
  include Blacklight::LayoutHelperBehaviorExt
end

__loading_end(__FILE__)

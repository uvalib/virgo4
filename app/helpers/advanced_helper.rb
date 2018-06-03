# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Helper methods for the advanced search form.
#
# Replaces the Blacklight Advanced Search module with local behavior
# definitions.
#
module AdvancedHelper
  include BlacklightAdvancedSearch::AdvancedHelperBehaviorExt
end

__loading_end(__FILE__)

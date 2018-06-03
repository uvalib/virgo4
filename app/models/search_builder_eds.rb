# app/models/blacklight/search_builder_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds/search_builder_behavior_eds'

class SearchBuilderEds < Blacklight::SearchBuilder
  include Blacklight::Eds::SearchBuilderBehaviorEds
  include BlacklightAdvancedSearch::AdvancedSearchBuilderExt
  self.default_processor_chain += SB_ADV_SEARCH_FILTERS
end

__loading_end(__FILE__)

# app/models/blacklight/search_builder.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/solr/search_builder_behavior_ext'

# SearchBuilder
#
# @example Adding a new step to the processor chain
#   self.default_processor_chain += [:add_custom_data_to_query]
#
#   def add_custom_data_to_query(solr_parameters)
#     solr_parameters[:custom] = blacklight_params[:user_value]
#   end
#   
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehaviorExt
  include BlacklightAdvancedSearch::AdvancedSearchBuilderExt
  self.default_processor_chain += SB_ADV_SEARCH_FILTERS
end

__loading_end(__FILE__)

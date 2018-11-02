# app/models/blacklight/search_builder.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/search_builder'
require 'blacklight/lens/search_builder_behavior'

# SearchBuilder
#
# @example Adding a new step to the processor chain
#   self.default_processor_chain += [:add_custom_data_to_query]
#
#   def add_custom_data_to_query(solr_parameters)
#     solr_parameters[:custom] = blacklight_params[:user_value]
#   end
#
# @see Blacklight::SearchBuilder
# @see Blacklight::Lens::SearchBuilderBehavior
#
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Lens::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]
end

__loading_end(__FILE__)


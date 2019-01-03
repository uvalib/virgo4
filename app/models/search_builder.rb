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

  # Add BlacklightAdvancedSearch::AdvancedSearchBuilder search processors.
  self.default_processor_chain +=
    %i(add_advanced_parse_q_to_solr add_advanced_search_to_solr)

  # ===========================================================================
  # :section: Blacklight::SearchBuilder overrides
  # ===========================================================================

  public

  # Initialize a new instance
  #
  # @param [Array] options
  #
  # @overload initialize(scope)                 - When created externally.
  #   @param [Object] scope                       The source of filter methods.
  #
  # @overload initialize(chain, scope)          - When used internally.
  #   @param [Array<Symbol>, TrueClass] chain     Filter methods used in place
  #                                                 of #default_processor_chain
  #   @param [Object] scope                       The source of filter methods.
  #
  # This method overrides:
  # @see Blacklight::SearchBuilder#initialize
  #
  # == Usage Notes
  # The first form is used when an instance is created externally.  In this
  # case the #search_builder_processors defined within the associated
  # Blacklight::Configuration are added to
  # SearchBuilder#default_processor_chain.
  #
  # The second form is used from SearchBuilder#append or SearchBuilder#except
  # in the process of adding or removing processor filters.  Here the provided
  # processor chain is used as provided.
  #
  def initialize(*options)
    super
    if options.size == 1
      blacklight_config =
        (@scope if @scope.is_a?(Blacklight::Configuration)) ||
        (@scope.blacklight_config if @scope.respond_to?(:blacklight_config))
      added_processors = blacklight_config&.search_builder_processors.presence
      @processor_chain += added_processors if added_processors.is_a?(Array)
    end
  end

end

__loading_end(__FILE__)

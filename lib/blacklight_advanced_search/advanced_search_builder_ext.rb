# lib/blacklight_advanced_search/advanced_search_builder_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module BlacklightAdvancedSearch

  # BlacklightAdvancedSearch::AdvancedSearchBuilderExt
  #
  # @see BlacklightAdvancedSearch::AdvancedSearchBuilder
  #
  module AdvancedSearchBuilderExt

    include BlacklightAdvancedSearch::AdvancedSearchBuilder
    include Blacklight::SearchFieldsExt
    include LensHelper

    # =========================================================================
    # :section:
    # =========================================================================

    public

    SB_ADV_SEARCH_FILTERS = %i(
      add_advanced_parse_q_to_solr
      add_advanced_search_to_solr
    )

  end

end

__loading_end(__FILE__)

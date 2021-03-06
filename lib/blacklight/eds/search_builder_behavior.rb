# lib/blacklight/eds/search_builder_behavior.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'blacklight/lens/search_builder_behavior'

module Blacklight::Eds

  # Extensions to Blacklight SearchBuilder applicable to EBSCO EDS searches.
  #
  # This module extends:
  # @see Blacklight::Lens::SearchBuilderBehavior
  #
  module SearchBuilderBehavior

    extend ActiveSupport::Concern

    include Blacklight::Lens::SearchBuilderBehavior

    included do |base|

      __included(base, 'Blacklight::Eds::SearchBuilderBehavior')

      # The default controller for searches.
      #
      # @return [Class]
      #
      def default_catalog_controller
        ArticlesController
      end

    end

    # =========================================================================
    # :section: Blacklight::Solr::SearchBuilderBehavior overrides
    # =========================================================================

    public

    # Add simple or search term query.
    #
    # @param [Hash] solr_params
    #
    # @return [void]
    #
    # This method overrides:
    # @see Blacklight::Solr::SearchBuilderBehavior#add_query_to_solr
    #
    # NOTE: This might be oversimplified...
    #
    def add_query_to_solr(solr_params)
      sf = search_field
      solr_params[:search_field] = sf.key if sf
      q = blacklight_params[:q]
      if q.is_a?(Hash)
        q =
          if q.values.any?(&:blank?)
            'NOT *:*' # If any field params are empty, exclude *all* results.
          else
            q.map { |field, values|
              values = Array.wrap(values).map { |v| solr_param_quote(v) }
              values = values.join(' OR ')
              "#{field}:(#{values})"
            }.join(' AND ')
          end
      end
      solr_params[:q] = q if q.is_a?(String)
    end

  end

end

__loading_end(__FILE__)

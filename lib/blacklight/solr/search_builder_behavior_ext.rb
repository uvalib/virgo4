# lib/blacklight/solr/search_builder_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/search_builder_behavior'

module Blacklight::Solr

  # Extensions to Blacklight SearchBuilder applicable to Solr searches.
  #
  # This module extends:
  # @see Blacklight::Solr::SearchBuilderBehavior
  #
  module SearchBuilderBehaviorExt

    extend ActiveSupport::Concern

    include Blacklight::SearchBuilderBehavior

    SB_CATALOG_FILTERS = %i(
      show_only_public_records
      show_only_discoverable_records
      show_only_lens_records
    )

    # Code to be added to the controller class including this module.
    included do |base|

      __included(base, 'Blacklight::Solr::SearchBuilderBehaviorExt')

      self.default_processor_chain += SB_CATALOG_FILTERS

    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # show_only_public_records
    #
    # @param [Hash] solr_params       Hash to be modified.
    #
    # @return [void]
    #
    def show_only_public_records(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] << '-shadowed_location_facet:HIDDEN'
    end

    # show_only_discoverable_records
    #
    # @param [Hash] solr_params       Hash to be modified.
    #
    # @return [void]
    #
    def show_only_discoverable_records(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] << '-shadowed_location_facet:UNDISCOVERABLE'
    end

    # show_only_lens_records
    #
    # @param [Hash] solr_params       Hash to be modified.
    #
    # @return [void]
    #
    # TODO: Characteristic formats (etc) should be in the lens configuration
    # rather than embedded here.
    #
    def show_only_lens_records(solr_params)
      controller = blacklight_params[:controller]
      lens = controller ? lens_key_for(controller) : current_lens_key
      formats =
        case lens
          when :video then ['Video']
          when :music then ['Sound Recording', 'Musical Score']
        end
      if formats
        formats.map! { |f| f.include?(' ') ? %Q("#{f}") : f }
        formats = formats.join(' OR ')
        solr_params[:fq] ||= []
        solr_params[:fq] << "format_facet:#{formats}"
      end
    end

  end

end

__loading_end(__FILE__)

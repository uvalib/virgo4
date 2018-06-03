# lib/blacklight/search_builder_behavior.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Blacklight

  # Extensions to Blacklight SearchBuilder applicable to all types of searches.
  #
  # This module extends:
  # @see Blacklight::Solr::SearchBuilderBehavior
  #
  module SearchBuilderBehavior

    extend ActiveSupport::Concern

    include Blacklight::Solr::SearchBuilderBehavior
    include LensHelper

    # Code to be added to the controller class including this module.
    included do |base|

      __included(base, 'Blacklight::SearchBuilderBehavior')

    end

    # =========================================================================
    # :section: Blacklight::SearchBuilder replacements
    # =========================================================================

    public

    # Sets the facet that this query pertains to, for the purpose of facet
    # pagination.
    #
    # @param [String, Symbol] value   Facet name.
    #
    # @return [String]
    #
    def facet=(value)
      params_will_change!
      @facet = value.to_s
    end

    # Used in two ways:
    #
    # @overload facet                 With no *value* just returns @facet.
    #
    #   @return [String, nil]
    #
    # @overload facet(value)          Within a search builder chain.
    #
    #   @param [String, Symbol] value   Facet name.
    #
    #   @return [self]
    #
    def facet(value = nil)
      if value
        self.tap { @facet = value.to_s }
      else
        @facet
      end
    end

    # sort
    #
    # @return [String, nil]
    #
    # This method will override:
    # @see Blacklight::SearchBuilder#sort
    #
    def sort
      sort_param = blacklight_params[:sort].to_s.presence
      sort_field =
        if sort_param
          # Check for sort field key or match with sort string.
          blacklight_config.sort_fields.find { |key, field_def|
            (sort_param == key) || (sort_param == field_def.sort)
          }&.last
        else
          # No sort param provided, use default.
          blacklight_config.default_sort_field
        end
      # If sort field was not determined, :sort may be a Solr sort string.
      sort_field ? sort_field.sort : sort_param
    end

    # search_field
    #
    # @return [Blacklight::Configuration::SearchField, nil]
    #
    # This method will override:
    # @see Blacklight::SearchBuilder#search_field
    #
    def search_field
      sf = blacklight_params[:search_field].to_s
      blacklight_config.search_fields[sf] if sf.present?
    end

    # =========================================================================
    # :section: Blacklight::Solr::SearchBuilderBehavior overrides
    # =========================================================================

    public

    # Look up facet limit for given facet_field. Will look at config, and
    # if config is 'true' will look up from Solr @response if available. If
    # no limit is available, return nil.
    #
    # Used from #add_facetting_to_solr to supply f.fieldname.facet.limit values
    # in Solr request (no @response available), and used in display (with
    # @response available) to create a facet paginator with the right limit.
    #
    # @param [String, Symbol] facet
    #
    # @param [Integer, nil]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#facet_limit_for
    #
    def facet_limit_for(facet)
      limit = blacklight_config.facet_fields[facet.to_s]&.limit
      limit = blacklight_config.default_facet_limit if limit.is_a?(TrueClass)
      limit
    end

    # A helper method used for generating Solr LocalParams, put quotes around
    # the term unless it's a simple word. Escape internal quotes if needed.
    #
    # @param [String]    value
    # @param [Hash, nil] options
    #
    # @return [String]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#solr_param_quote
    #
    def solr_param_quote(value, options = nil)
      value = value.to_s.squish
      quote = options&.dig(:quote) || %q(")
      if value =~ /^[a-z0-9$_^\-]+$/i
        value
      else
        # Strip outer balanced quotes.
        %w( " ' ).each do |c|
          value = value[1..-2] if value.start_with?(c) && value.end_with?(c)
        end
        # Yes, we need crazy escaping here, to deal with regexp esc too!
        value.gsub!(/['"]/, (%q(\\\\) + '\0'))
        "#{quote}#{value}#{quote}"
      end
    end

    # =========================================================================
    # :section: Blacklight::Solr::SearchBuilderBehavior overrides
    # =========================================================================

    private

    # Convert a facet/value pair into a Solr :fq parameter.
    #
    # @param [String, Symbol] facet_field
    # @param [String]         value
    #
    # @param [String]
    #
    # This method overrides:
    # @Blacklight::Solr::SearchBuilderBehavior#facet_value_to_fq_string
    #
    def facet_value_to_fq_string(facet_field, value)
      facet_field  = facet_field.to_s
      facet_config = blacklight_config.facet_fields[facet_field]
      query = facet_config&.query
      if query
        # Exclude all documents if the specified facet key was not found.
        query[value] ? query[value][:fq] : '-*:*'
      else
        solr_field   = facet_config&.field || facet_field
        local_params = ("tag=#{facet_config.tag}" if facet_config&.tag)
        if value.is_a?(Range)
          prefix = nil
          value  = "#{solr_field}:[#{value.first} TO #{value.last}]"
        else
          prefix = "term f=#{solr_field}"
          value  = convert_to_term_value(value)
        end
        prefix = [prefix, local_params].compact.join(' ').presence
        prefix ? "{!#{prefix}}#{value}" : value
      end
    end

  end

end

__loading_end(__FILE__)

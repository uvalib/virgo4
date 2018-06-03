# app/controllers/concerns/config/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'i18n'
require 'uva'

module Config

  # Config::Common
  #
  # Constants and methods for use within configuration blocks.
  #
  module Common

    include UVA::Constants

    # Options for displaying separator between metadata items with multiple
    # values.
    HTML_LINES = %i(
      words_connector
      two_words_connector
      last_word_connector
    ).map { |k| [k, HTML_NEW_LINE] }.to_h.deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    # Shortcut to `I18n.translate`.
    #
    # @param [Array] args
    #
    # @return [String, nil]
    #
    def t(*args)
      I18n.translate(*args)
    end

    # Attempt to find a localized string based on a succession of I18n keys
    # and/or literal strings.
    #
    # @param [Array<Symbol,String>] *i18n_keys
    #
    # @return [String]
    #
    def try_translate(*i18n_keys)
      options = i18n_keys.last.is_a?(Hash) ? i18n_keys.pop.dup : {}
      primary_key, *other_keys = i18n_keys.compact
      options[:default] = other_keys + Array.wrap(options[:default])
      I18n.translate(primary_key, options)
    end

    # Lookup a localized label for the given configuration field.
    #
    # @param [Blacklight::Configuration::Field] field
    # @param [Symbol, String, nil]              field_type
    # @param [Symbol, String, nil]              lens
    #
    # @return [String]
    #
    def field_label(field, field_type = nil, lens = nil)
      name = field.key.to_s.sub(/^eds_/, '').sub(/_(facet|display)$/, '')
      type = field_type.to_s.presence
      type = "#{type}_field" if type && !type.end_with?('_field')
      lens = Blacklight::Lens.key_for(lens, false)
      keys = []
      keys << :"blacklight.#{lens}.#{type}.#{name}" if lens && type
      keys << :"blacklight.#{lens}.field.#{name}"   if lens
      keys << :"blacklight.#{type}.#{name}"         if type
      keys << :"blacklight.field.#{name}"
      keys << name.humanize
      keys.delete_if(&:blank?)
      try_translate(*keys)
    end

    # Get field labels from I18n, including labels specific to this lens and
    # perform any updates that are appropriate for all fields of a given type
    # regardless of the lens.
    #
    # @param [Blacklight::Configuration] config
    # @param [Symbol, String, nil]       lens_key
    #
    def finalize_configuration(config, lens_key = nil)

      lens_key ||= config.lens_key

      # === Facet fields ===

      # Set facet field labels for this lens.
      config.facet_fields.each_pair do |_, field|
        field.label = field_label(field, 'facet_field', lens_key)
      end

      # Have Blacklight send all facet field names to Solr.
      # (Remove to use Solr request handler defaults or to have no facets.)
      config.add_facet_fields_to_solr_request!

      # === Index (results page) metadata fields ===

      # Set index field labels for this lens.
      config.index_fields.each_pair do |_, field|
        field.label = field_label(field, 'index_field', lens_key)
      end

      # === Item details (show page) metadata fields ===

      # Set show field labels for this lens and supply options that apply to
      # multiple field configurations.
      config.show_fields.each_pair do |_, field|
        field.label = field_label(field, 'show_field', lens_key)
        field.separator_options ||= HTML_LINES
      end

      # === Search fields ===

      # Set search field labels for this lens.
      config.search_fields.each_pair do |_, field|
        field.label = field_label(field, 'search_field', lens_key)
      end

      # === Sort fields ===

      # Set sort field labels for this lens.
      config.sort_fields.each_pair do |_, field|
        field.label = field_label(field, 'sort_field', lens_key)
      end

    end

    # Generate a log message if the configured Solr is not appropriate.
    #
    # @params [TrueClass, FalseClass] required
    #
    # @return [true]                  If the right Solr is configured.
    # @return [false]                 Otherwise
    #
    def production_solr(required)
      prod = Blacklight.connection_config[:url].include?(PRODUCTION_SUBNET)
      return true if required == prod
      Log.error {
        "#{name}: This configuration will not work without changing " \
        'config/blacklight.yml'
      }
    end

  end

end

__loading_end(__FILE__)

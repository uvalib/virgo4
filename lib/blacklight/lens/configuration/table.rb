# lib/blacklight/lens/configuration/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens/configuration/mapper'

module Blacklight::Lens

  module Configuration

    # Blacklight::Lens::Configuration::Table
    #
    class Table

      include Blacklight::Lens::Configuration
      include Mapper

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Initialize a new instance.
      #
      def initialize
        @hash = lens_keys.map { |k| [k, nil] }.to_h.with_indifferent_access
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Methods to delegate to the internal hash member.
      #
      TABLE_METHODS = %i(
        keys
        size
        length
        map
        empty?
        blank?
        present?
        key?
        has_key?
      ).freeze

      delegate *TABLE_METHODS, to: :@hash

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Retrieve lens by key.
      #
      # @param [String, Symbol] key
      #
      # @return [Blacklight::Lens::Configuration::Entry, nil]
      #
      def [](key)
        key = key_for(key, false)
        @hash[key] if key
      end

      # Set lens by key.
      #
      # @param [String, Symbol]   key
      # @param [Blacklight::Lens::Configuration::Entry] entry
      #
      # @return [Blacklight::Lens::Configuration::Entry, nil]
      #
      def []=(key, entry)
        key = key_for(key) unless valid_key?(key)
        @hash[key] = entry if key
      end

      # Delegate all other methods to @hash.
      #
      # @param [Symbol] method
      # @param [Array]  args
      #
      # @return [*]
      #
      # == Implementation Notes
      # This might be temporary; it's probably better to avoid #method_missing
      # if possible and explicitly add needed delegations to #TABLE_METHODS.
      #
      def method_missing(method, *args, &block)
        logger.info { "NOTE: lens table delegating #{method} to @hash"}
        @hash.send(method, *args, &block)
      end

    end

  end

end

__loading_end(__FILE__)

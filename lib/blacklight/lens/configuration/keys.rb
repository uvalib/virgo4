# lib/blacklight/lens/configuration/keys.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Blacklight::Lens

  module Configuration

    # Blacklight::Lens::Configuration::Keys
    #
    module Keys

      extend self

      # All (known) lens keys.
      LENS_KEYS = [
        #:all,        # TODO: Combined results controller?
        :catalog,
        :articles,
        :video,
        :music,
      ].freeze

      # Explicitly state the key for the default lens.
      DEFAULT_LENS_KEY = :catalog

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # The keys for all search lenses.
      #
      # @return [Array<Symbol>]
      #
      def lens_keys
        LENS_KEYS
      end

      # The key for the default search lens.
      #
      # @return [Symbol]
      #
      def default_lens_key
        DEFAULT_LENS_KEY
      end

      # Indicate whether *key* is a valid search lens key.
      #
      # @param [Symbol] key
      #
      def valid_key?(key)
        key.respond_to?(:to_sym) && lens_keys.include?(key.to_sym)
      end

      # validate_key
      #
      # @param [Object]      object     Object to check.
      # @param [String, nil] name       Key source for error message.
      #
      # @raise [RuntimeError]           If *object* is not valid.
      #
      def validate_key(object, name = nil)
        key =
          if object.respond_to?(:key)
            object.send(:key)
          elsif !object.is_a?(Class)
            object
          end
        error =
          if key.nil?
            "#{object} does not implement #key method"
          elsif !valid_key?(key)
            name ||= "#{object}.key" if object.is_a?(Class)
            name ||= 'Lens key'
            "#{name} (#{key.inspect}) not in #{lens_keys.inspect}"
          end
        raise "\n\n#{error}\n\n" if error
      end

    end

  end

end

__loading_end(__FILE__)

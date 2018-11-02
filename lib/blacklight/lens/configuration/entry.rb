# lib/blacklight/lens/configuration/entry.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens/configuration/mapper'

module Blacklight::Lens

  module Configuration

    # Blacklight::Lens::Configuration::Entry
    #
    class Entry

      include Blacklight::Lens::Configuration
      include Mapper
      extend  Mapper

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # @return [Symbol]
      attr_reader :key

      # @return [Blacklight::Configuration]
      attr_reader :blacklight_config

      # Methods to delegate to :blacklight_config.
      #
      # @see Blacklight::Configuration#default_values
      # @see Blacklight::Configuration#instance_methods
      #
      CONFIG_METHODS = (
        Blacklight::Configuration.default_values.keys +
        Blacklight::Configuration.instance_methods(false)
      ).reject { |k| k.blank? || (k =~ /=/) }.map(&:to_sym).sort.uniq.freeze

      delegate *CONFIG_METHODS, to: :blacklight_config

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Initialize a new instance.
      #
      # @param [Blacklight::Controller, Blacklight::Configuration] obj
      #
      def initialize(obj)
        @controller = (obj if obj.is_a?(Blacklight::Controller))
        @blacklight_config = @controller&.blacklight_config || obj
        @key = @blacklight_config.lens_key
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # The controller class associated with the lens table entry.
      #
      # @return [Class]
      #
      def controller_class
        @controller_class ||= @controller&.class || self.class.class_for(@key)
      end

      # If this lens entry was created from the associated controller then the
      # instance will be a reference to the live controller.  In all other
      # cases the instance is created dynamically.
      #
      # @param [Blacklight::Lens::Response, nil] resp
      # @param [ActionDispatch::Request, nil]    req
      #
      # @return [Blacklight::Controller]
      #
      def instance(resp = nil, req = nil, &block)
        @controller ||= controller_class.new
        resp = @response if !resp && respond_to?(:@response)
        req  = request   if !req  && respond_to?(:request)
        @controller.instance_eval {
          @blacklight_config ||= blacklight_config
          @response          ||= resp if resp
          @_request          ||= req  if req
          self
        }
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # The controller class implicitly associated with a lens.
      #
      # @param [String, Symbol, Class, Entry, Blacklight::Controller] name
      #
      # @return [Class]
      #
      def self.class_for(name = nil)
        name ||= @key
        name = key_for_name(name)
        "#{name}_controller".camelize.constantize
      end

    end

  end

end

__loading_end(__FILE__)

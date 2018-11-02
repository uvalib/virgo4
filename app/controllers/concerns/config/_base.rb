# app/controllers/concerns/config/_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Config

  # Config::Base
  #
  module Base

    extend ActiveSupport::Concern

    include UVA::Constants

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # Methods associated with the configuration class.
    #
    module ClassMethods

      # The lens key for the configuration class.
      #
      # @return [Symbol]
      #
      attr_accessor :key

      # The Blacklight configuration associated with the configuration class.
      #
      # @return [Blacklight::Configuration]
      #
      def blacklight_config
        Blacklight::Lens[@key].blacklight_config
      end

      # Make a deep copy of the Blacklight configuration.
      #
      # @param [Blacklight::Controller] other_controller
      #
      # @return [Blacklight::Configuration]
      #
      def deep_copy(other_controller)
        blacklight_config.inheritable_copy(other_controller)
      end

      # Set key.
      #
      # @param [Symbol] lens_key
      #
      # @return [Symbol]
      #
      def key=(lens_key)
        Log.error(__method__, lens_key.inspect, 'was', @key.inspect) if @key
        @key = lens_key
      end

      # Remove facet fields from a configuration.
      #
      # @param [Blacklight::Configuration] config
      # @param [Array<String>]             names
      #
      # @return [void]
      #
      def remove_facets!(config, *names)
        names = names.flatten.flat_map { |type| %W(#{type} #{type}_f) }.uniq
        config.facet_fields.extract!(*names)
      end

    end

    # Define these as instance methods as well as class methods.
    include ClassMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new Config::Base-derivative instance by adding its
    # Blacklight::Configuration to the Blacklight::Lens table.
    #
    # @param [::Config::Base, Blacklight::Configuration] cfg
    #
    def register(cfg)
      cfg  = cfg.blacklight_config if cfg.respond_to?(:blacklight_config)
      @key = cfg.lens_key
      self.class.key = @key
      Blacklight::Lens.add_new(@key, cfg)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  autoload :Articles, 'config/articles'
  autoload :Catalog,  'config/catalog'
  autoload :Music,    'config/music'
  autoload :Video,    'config/video'

end

__loading_end(__FILE__)

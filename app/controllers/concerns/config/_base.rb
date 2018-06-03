# app/controllers/concerns/config/_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'uva'

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
      # @return [Blacklight::Configuration]
      #
      def deep_copy
        blacklight_config.deep_copy
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

    end

    # Define these as instance methods as well as class methods.
    include ClassMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    # @param [Blacklight::Configuration] config
    # @param [Symbol, nil]               lens_key
    #
    def initialize(config, lens_key = nil)
      lens_key ||= config.lens_key
      @key       = lens_key
      self.key ||= lens_key
      Blacklight::Lens.add_new(@key, config)
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

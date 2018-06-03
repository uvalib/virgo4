# lib/blacklight/lens/entry.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Blacklight::Lens

  # Blacklight::Lens::Entry
  #
  class Entry

    include Blacklight::Lens::Mapper

    # Methods to delegate to :blacklight_config.
    # @see Blacklight::Configuration#default_values
    # @see Blacklight::Configuration#instance_methods
    CONFIG_METHODS = (
      Blacklight::Configuration.default_values.keys +
      Blacklight::Configuration.instance_methods(false)
    ).reject { |k| k.blank? || (k =~ /=/) }.map(&:to_sym).sort.uniq.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # @return [Symbol]
    attr_reader :key

    # @return [Blacklight::Configuration]
    attr_reader :blacklight_config

    # Initialize a self instance.
    #
    # @param [Symbol]                       key
    # @param [Blacklight::Configuration]    config
    # @param [Blacklight::Controller, nil]  instance
    #
    def initialize(key, config, instance = nil)
      @key               = key
      @blacklight_config = config
      @controller        = instance
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    delegate *CONFIG_METHODS, to: :blacklight_config

    # class_for
    #
    # @param [Object] name
    #
    # @return [Class]
    #
    def class_for(name = nil)
      name ||= @key
      name = key_for_name(name)
      "#{name}_controller".camelize.constantize
    end

    # controller_class
    #
    # @return [Class]
    #
    def controller_class
      @controller_class ||= @controller ? @controller.class : class_for(@key)
    end

    # If this lens entry was created from the associated controller then the
    # instance will be a reference to the live controller.  In all other cases
    # the instance is created dynamically.
    #
    # @param [Blacklight::Solr::Response, nil] resp
    # @param [ActionDispatch::Request, nil]    req
    #
    # @return [Blacklight::Controller]
    #
    def instance(resp = nil, req = nil, &block)
      if @controller
        @controller
      else
        resp = @response if !resp && respond_to?(:@response)
        req  = request   if !req  && respond_to?(:request)
        controller_class.new.instance_eval {
          @blacklight_config ||= blacklight_config
          @response          ||= resp if resp
          @_request          ||= req  if req
          self
        }
      end
    end

  end

end

__loading_end(__FILE__)

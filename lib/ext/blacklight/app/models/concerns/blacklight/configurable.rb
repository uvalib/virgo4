# lib/ext/blacklight/app/models/concerns/blacklight/configurable.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Inject Blacklight::Configurable extensions and replacement methods.

__loading_begin(__FILE__)

require 'blacklight/lens'

override Blacklight::Configurable do

  include Blacklight::Lens

  # Instance methods for blacklight_config, so get a deep copy of the
  # class-level config.
  #
  # @return [Blacklight::Configuration]
  #
  # This method overrides:
  # @see Blacklight::Configurable#blacklight_config
  #
  def blacklight_config(name = nil)
    if name
      blacklight_config_for(name)
    elsif @blacklight_config
      @blacklight_config
    else
      Log.warn(__method__, '@blacklight_config unset')
      @blacklight_config = current_lens.blacklight_config
    end
  rescue => e
    Log.warn {
      [
        "[Configurable] #{e}",
        "class #{self.class}",
        "ancestors #{self.class.ancestors}"
      ].join("\n  ")
    }
    raise e
  end

  # ===========================================================================
  # :section: Blacklight::Configurable::ClassMethods overrides
  # ===========================================================================

  public

  module ClassMethods

    include Blacklight::Configurable
    include Blacklight::Lens

    # =========================================================================
    # :section: Blacklight::Configurable::ClassMethods overrides
    # =========================================================================

    public

    # Lazy-load a deep_copy of superclass configuration if present (or a
    # default_configuration if not), which will be legacy load or new empty
    # config.
    #
    # Note that the @blacklight_config variable is a Ruby
    # "instance method on class object" that won't be automatically available
    # to subclasses, that's why we lazy load to "inherit" how we want.
    #
    # @param [String, Symbol, ..., nil] name
    #
    # @return [Blacklight::Configuration]
    #
    # This method overrides:
    # @see Blacklight::Configurable::ClassMethods#blacklight_config
    #
    def blacklight_config(name = nil)
      if name
        blacklight_config_for(name)
      else
        @blacklight_config ||= current_lens.blacklight_config
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Fields that are suppressed in the default inspection of a configuration.
    NO_INSPECT =
      %i(facet_fields index_fields show_fields search_fields sort_fields)

    # Generate an easier-to-read inspection of a configuration by coverting
    # Hash-like elements to Hash.
    #
    # @param [ActiveSupport::OrderedOptions] config
    # @param [TrueClass, FalseClass, nil]    all
    #
    # @return [String]
    #
    def config_inspect(config, all = false)
      h = config.to_h
      h = h.except(*NO_INSPECT) unless all
      hashify(h).pretty_inspect.gsub(/:([^=\n]+)(=>)/, '\1 \2 ')
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Covert Hash-like elements to Hash.
    #
    # @param [Object] value
    #
    # @return [Object]
    #
    def hashify(value)
      case value
        when Hash, OpenStruct
          value.to_h.map { |k, v| [hashify(k), hashify(v)] }.to_h
        when Array
          value.map { |v| hashify(v) }
        else
          value
      end
    end

  end

end

__loading_end(__FILE__)

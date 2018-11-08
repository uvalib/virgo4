# lib/blacklight/lens.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight_advanced_search'
require_subdir(__FILE__, 'lens/configuration')
require_subdir(__FILE__, 'lens')
require_subdir(__FILE__, 'solr')
require 'blacklight/eds'

module Blacklight

  # Blacklight::Lens
  #
  module Lens

    include Blacklight::Lens::Configuration
    include Mapper
    extend  Mapper
    extend  self

    # =========================================================================
    # :section: Module methods
    # =========================================================================

    public

    class << self

      include Blacklight::Lens::Configuration
      include Mapper

      # =======================================================================
      # :section: Lens table
      # =======================================================================

      public

      TABLE_METHODS = Table::TABLE_METHODS + %i([] []=)

      delegate *TABLE_METHODS, to: :table

      # A mapping of lens keys to lens entries.
      #
      # @return [Hash{Symbol, Blacklight::Lens::Entry}]
      #
      def table
        @table ||= Table.new
      end

      # Add a new search lens entry if one was not already present.
      #
      # @param [Symbol]                                            key
      # @param [Blacklight::Controller, Blacklight::Configuration] obj
      # @param [TrueClass, FalseClass, nil]                        force
      #
      # @return [Blacklight::Lens::Entry]
      #
      def add_new(key, obj, force = nil)
        entry = table[key]
        entry = table[key] = Entry.new(obj) if force || entry.blank?
        entry
      end

      # =======================================================================
      # :section: Lens routes
      # =======================================================================

      public

      # Add routes.
      #
      # @param [ActionDispatch::Routing::RouteSet] router
      # @param [Hash, nil]                         opt
      #
      # @return [void]
      #
      def add_routes(router, opt = nil)
        Blacklight::Lens::Routes.new(router, opt).draw
      end

    end

    # =========================================================================
    # :section: Instance methods
    # =========================================================================

    public

    # The current lens or the lens indicated by *object* if it is given.
    #
    # The method returns *nil* only when *object* does not map to a valid lens.
    #
    # @param [Object]                        object
    # @param [TrueClass, FalseClass, Symbol] default
    #
    # @raise [RuntimeError]             If the default lens is missing.
    #
    # @return [Blacklight::Lens::Entry]
    # @return [nil]     If *obj* is invalid and *default* is *false* or *nil*.
    #
    def lens_entry(object, default = true)
      lens = nil
      default = current_lens_key if default.is_a?(TrueClass)
      [object, default]
        .map { |item| Blacklight::Lens.key_for(item, false) if item.present? }
        .compact
        .uniq
        .find { |key|
          # If there is no entry for the key create one by instantiating the
          # controller class associated with it (which will register an entry
          # in the lens table).
          Entry.class_for(key).new unless Blacklight::Lens[key]
          lens = Blacklight::Lens[key]
        }
      if !lens && default
        raise "Lens::Table has no entry for #{object || default}"
      end
      lens
    end

    # The entry for the lens specified or inferred by *object*.
    #
    # If no lens can be determined for the current context, the result will be
    # the the same as for #current_lens.
    #
    # @return [Blacklight::Lens::Entry]
    #
    def lens_for(object)
      lens_entry(object)
    end

    # The current lens.
    #
    # If no lens can be determined for the current context, the result will be
    # the lens entry associated with #default_lens_key.
    #
    # @return [Blacklight::Lens::Entry]
    #
    def current_lens
      lens_for(nil)
    end

    # lens_key_for
    #
    # If no lens can be determined for the current context, the result will be
    # Blacklight::Lens#default_lens_key.
    #
    # @param [Object]                        object
    # @param [TrueClass, FalseClass, Symbol] default
    #
    # @return [Symbol]
    #
    def lens_key_for(object, default = true)
      Blacklight::Lens.key_for(object, default)
    end

    # current_lens_key
    #
    # @return [Symbol]
    #
    # == Usage Notes
    # This is defined so that `current_lens_key == current_lens.key`.
    #
    def current_lens_key
      default_lens_controller&.lens_key || default_lens_key
    end

    # Blacklight configuration for the lens specified or inferred by *object*.
    #
    # @param [Object] object
    #
    # @return [Blacklight::Configuration]
    #
    # == Usage Notes
    # This is defined so that
    # `blacklight_config_for(nil) == current_lens.blacklight_config`.
    #
    def blacklight_config_for(object)
      lens_for(object).blacklight_config
    end

    # Blacklight configuration for the default lens.
    #
    # @return [Blacklight::Configuration]
    #
    def default_blacklight_config
      blacklight_config_for(default_lens_key)
    end

    # For the current scope, the controller which will handle lens actions.
    #
    # Within controllers like CatalogController, ArticlesController, etc. this
    # will return the controller itself.
    #
    # Within controllers like BookmarksController this will return *nil* since
    # that controller does not directly handle lens actions.
    #
    # @param [Object, nil] scope      By default, `self`.
    #
    # @return [Blacklight::Controller, nil]
    #
    def default_lens_controller(scope = nil)
      scope ||= self
      scope = scope.controller if scope.respond_to?(:controller)
      if scope.respond_to?(:default_catalog_controller)
        scope.default_catalog_controller
      elsif lens_key_for(scope, false)
        scope
      end
    end

  end

  # Sanity check.
  Blacklight::Lens.validate_key(Blacklight::Lens.default_lens_key)

end

__loading_end(__FILE__)

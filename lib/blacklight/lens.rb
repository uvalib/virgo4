# lib/blacklight/lens.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight_advanced_search'

require 'blacklight/lens/config'
require 'blacklight/lens/mapper'
require 'blacklight/lens/table'
require 'blacklight/lens/entry'
require 'blacklight/lens/routes'

module Blacklight

  autoload :SearchStateExt, 'blacklight/search_state_ext'

  # Blacklight::Lens
  #
  module Lens

    include Blacklight::Lens::Mapper
    extend self

    TABLE_METHODS = Blacklight::Lens::Table::TABLE_METHODS + %i([] []=)

    # =========================================================================
    # :section: Module methods
    # =========================================================================

    public

    delegate *TABLE_METHODS, to: :table

    # table
    #
    # @return [Hash{Symbol, Blacklight::Lens::Entry}]
    #
    def table
      @table ||= Blacklight::Lens::Table.new
    end

    # Add a new search lens entry if one was not already present.
    #
    # @param [Symbol]                     key
    # @param [Blacklight::Configuration]  config
    # @param [TrueClass, FalseClass, nil] force
    #
    # @return [Blacklight::Lens::Entry]
    #
    def add_new(key, config, force = nil)
      if !force && (current_entry = table[key])
        current_entry
      else
        table[key] = Blacklight::Lens::Entry.new(key, config)
      end
    end

    # default_lens
    #
    # @return [Blacklight::Lens::Entry]
    #
    def default_lens
      table[default_key]
    end

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

  # Sanity check.
  Blacklight::Lens.validate_key(Blacklight::Lens.default_key)

end

__loading_end(__FILE__)

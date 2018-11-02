# lib/blacklight/lens/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  # Blacklight::Lens::Routes
  #
  class Routes

    DEFAULT_ROUTE_SETS = Blacklight::Lens::Configuration::Keys.lens_keys

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize an instance.
    #
    # @param [ActionDispatch::Routing::RouteSet] router
    # @param [Hash, nil]                         options
    #
    def initialize(router, options = nil)
      @router  = router
      @options = options || {}
    end

    # Run the methods that generate the routes.
    #
    # @return [void]
    #
    def draw
      route_sets.each { |route_set| self.send(route_set) }
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # default_route_sets
    #
    # @return [Array<Symbol>]
    #
    def default_route_sets
      DEFAULT_ROUTE_SETS
    end

    # route_sets
    #
    # @return [Array<Symbol>]
    #
    def route_sets
      only   = Array.wrap(@options[:only] || default_route_sets)
      except = Array.wrap(@options[:except])
      only - except
    end

    # add_routes
    #
    # @return [void]
    #
    def add_routes(&block)
      @router.instance_exec(@options, &block)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    module RouteSets

      DEFAULT_ROUTE_SETS.each do |lens|
        eval <<-EOS
          def #{lens}
            add_routes do
              get '#{lens}/home',       to: redirect('/#{lens}')

              get '#{lens}/index',      to: redirect('/#{lens}?q=*'),
                                        as: '#{lens}_all'

              get '#{lens}/advanced',   to: '#{lens}_advanced#index',
                                        as: '#{lens}_advanced_search',
                                        controller: '#{lens}_advanced'

              get '#{lens}/opensearch', to: '#{lens}#opensearch'
            end
          end
        EOS
      end

    end

    include RouteSets

  end

end

__loading_end(__FILE__)

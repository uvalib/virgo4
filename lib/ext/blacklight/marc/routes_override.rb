# lib/ext/blacklight/marc/routes_override.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/marc'
require 'blacklight/marc/routes'
require 'blacklight/lens'

module Blacklight::Marc

  class Routes

    include Blacklight::Lens::Config

    # =========================================================================
    # :section: Blacklight::Marc::Routes overrides
    # =========================================================================

    protected

    # default_route_sets
    #
    # @return [Array<Symbol>]
    #
    # This method overrides:
    # Blacklight::Marc::Routes#default_route_sets
    #
    def default_route_sets
      LENS_KEYS
    end

    # route_sets
    #
    # @return [Array<Symbol>]
    #
    # This method overrides:
    # Blacklight::Marc::Routes#route_sets
    #
    def route_sets
      only   = Array.wrap(@options[:only] || default_route_sets)
      except = Array.wrap(@options[:except])
      only - except
    end

    # =========================================================================
    # :section: Blacklight::Marc::Routes::RouteSets overrides
    # =========================================================================

    protected

    # The routes added by Blacklight::Marc.
    #
    module RouteSets

      include Blacklight::Lens::Config

      Blacklight::Lens::Config.keys.each do |lens|
        lv_opt = +", to: '#{lens}#librarian_view'"
        case lens
          when :catalog  then lv_opt << ", as: 'librarian_view_solr_document'"
          when :articles then lv_opt << ", as: 'librarian_view_eds_document'"
        end
        en_opt = +", to: '#{lens}#endnote', defaults: { format: 'endnote' }"
        case lens
          when :catalog  then en_opt << ", as: 'endnote_solr_document'"
          when :articles then en_opt << ", as: 'endnote_eds_document'"
        end
        eval <<-EOS
          def #{lens}
            add_routes do
              get '#{lens}/:id/librarian_view' #{lv_opt}
              get '#{lens}/:id/endnote'        #{en_opt}
            end
          end
        EOS
      end

    end

    include RouteSets

  end

end

__loading_end(__FILE__)

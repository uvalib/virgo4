# lib/ext/blacklight-marc/lib/blacklight/marc/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/marc/routes'
require 'blacklight/lens'

# Override Blacklight::Marc definitions.
#
# @see Blacklight::Marc::Routes
#
module Blacklight::Marc::RoutesExt

  DEFAULT_ROUTE_SETS = Blacklight::Lens::Configuration::Keys.lens_keys

  # ===========================================================================
  # :section: Blacklight::Marc::Routes overrides
  # ===========================================================================

  protected

  # default_route_sets
  #
  # @return [Array<Symbol>]
  #
  # This method overrides:
  # Blacklight::Marc::Routes#default_route_sets
  #
  def default_route_sets
    DEFAULT_ROUTE_SETS
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

  # ===========================================================================
  # :section: Blacklight::Marc::Routes overrides
  # ===========================================================================

  protected

  # Blacklight::Marc::RoutesExt::RouteSets
  #
  # == Usage Notes
  # Because this is 'included' after Blacklight::Marc::Routes::RouteSets, it
  # results in replacing Blacklight::Marc::Routes#catalog along with defining:
  #
  #   Blacklight::Marc::Routes#articles
  #   Blacklight::Marc::Routes#video
  #   Blacklight::Marc::Routes#music
  #
  module RouteSets

    DEFAULT_ROUTE_SETS.each do |lens|
      lv_opt =
        ", to: '#{lens}#librarian_view'" \
        ", as: 'librarian_view_#{lens}'"
      rw_opt = # TODO: remove?
        ", to: '#{lens}#refworks'" \
        ", as: 'refworks_#{lens}'" \
        ''
        #", defaults: { format: 'refworks_marc_txt' }"
      en_opt = # TODO: remove?
        ", to: '#{lens}#endnote'" \
        ", as: 'endnote_#{lens}'" \
        ", defaults: { format: 'endnote' }"
      zo_opt = # TODO: remove?
        ", to: '#{lens}#zotero'" \
        ", as: 'zotero_#{lens}'" \
        ", defaults: { format: 'ris' }"
      eval <<~EOF
        def #{lens}
          add_routes do
            get '#{lens}/:id/librarian_view' #{lv_opt}
            # get '#{lens}/refworks'         #{rw_opt} # TODO: remove?
            # get '#{lens}/refworks?id=:id'  #{rw_opt} # TODO: remove?
            # get '#{lens}/:id/endnote'      #{en_opt} # TODO: remove?
            # get '#{lens}/:id/zotero'       #{zo_opt} # TODO: remove?
          end
        end
      EOF
    end

  end

  include RouteSets

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Marc::Routes => Blacklight::Marc::RoutesExt

__loading_end(__FILE__)

# app/controllers/music_advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AdvancedController variant for music search.
#
# Compare with:
# @see CatalogAdvancedController
#
class MusicAdvancedController < BlacklightAdvancedSearch::AdvancedController

  include AdvancedSearchConcern
  include MusicConcern
  include LensConcern

  self.blacklight_config =
    ::Config::Music.new.deep_copy(self).tap do |config|

      # The advanced search form displays facets as a limit option.
      # By default it will use whatever facets, if any, are returned
      # by the Solr request handler in use. However, you can use
      # this config option to have it request other facet params than
      # default in the Solr request handler, in desired.
      config.advanced_search.form_solr_parameters ||= {}
      config.advanced_search.form_solr_parameters[:'facet.limit'] = -1

    end

end

__loading_end(__FILE__)

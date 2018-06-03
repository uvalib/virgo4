# app/controllers/concerns/music_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/music'

# CatalogConcern
#
module MusicConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'MusicConcern')

    include SolrConcern

    if base == MusicController
      self.blacklight_config = Config::Music.new.blacklight_config
    else
      copy_blacklight_config_from(MusicController)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The default controller for searches.
    #
    # @return [Class]
    #
    def default_catalog_controller
      MusicController
    end

    # The default controller for searches.
    #
    # @return [Class]
    #
    def self.default_catalog_controller
      MusicController
    end

  end

end

__loading_end(__FILE__)

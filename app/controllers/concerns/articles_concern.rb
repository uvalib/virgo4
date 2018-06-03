# app/controllers/concerns/articles_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/articles'

# ArticlesConcern
#
module ArticlesConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'ArticlesConcern')

    include EdsConcern

    if base == ArticlesController
      self.blacklight_config = Config::Articles.new.blacklight_config
    else
      copy_blacklight_config_from(ArticlesController)
    end

    # @see Blacklight::DefaultComponentConfiguration
    # @see Blacklight::Marc::Catalog

    #add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    #add_results_collection_tool(:sort_widget)
    #add_results_collection_tool(:per_page_widget)
    #add_results_collection_tool(:view_type_group)

    #add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    #add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    #add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    #add_show_tools_partial(:citation)

    #add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    #add_nav_action(:saved_searches, partial: 'blacklight/nav/saved_searches', if: :render_saved_searches?)
    #add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The default controller for searches.
    #
    # @return [Class]
    #
    def default_catalog_controller
      ArticlesController
    end

    # The default controller for searches.
    #
    # @return [Class]
    #
    def self.default_catalog_controller
      ArticlesController
    end

  end

end

__loading_end(__FILE__)

# app/controllers/concerns/history_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# HistoryConcern
#
module HistoryConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'HistoryConcern')

    include BlacklightAdvancedSearch::ControllerExt
    include RescueConcern
    include LensConcern

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Creates the @presenter used in
  # `app/views/search_history/index.json.jbuilder` and
  # `app/views/saved_searches/index.json.jbuilder`.
  #
  # @param [Array<Search>] searches
  #
  # @return [Blacklight::JsonPresenterExt]
  #
  def json_presenter(searches)
    Blacklight::JsonPresenterExt.new(nil, searches)
  end

end

__loading_end(__FILE__)

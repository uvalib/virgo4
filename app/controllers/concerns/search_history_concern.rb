# app/controllers/concerns/search_history_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SearchHistoryConcern
#
module SearchHistoryConcern

  extend ActiveSupport::Concern

  include Blacklight::Lens::Controller
  include Blacklight::Lens::SearchHistory

  included do |base|
    __included(base, 'SearchHistoryConcern')
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
  # @param [Symbol]        view       Default: :index.
  #
  # @return [Blacklight::Lens::JsonPresenter]
  #
  def json_presenter(searches, view: :index)
    json_presenter_class.new(searches, view: view)
  end

end

__loading_end(__FILE__)

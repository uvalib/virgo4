# app/presenters/blacklight/lens/search_bar_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::SearchBarPresenter
  #
  # @see Blacklight::SearchBarPresenter
  # @see Blacklight::Lens::PresenterBehaviors
  #
  class SearchBarPresenter < Blacklight::SearchBarPresenter

    include Blacklight::Lens::PresenterBehaviors

    # TODO: ???

  end

end

__loading_end(__FILE__)

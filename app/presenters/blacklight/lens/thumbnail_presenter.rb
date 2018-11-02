# app/presenters/blacklight/lens/thumbnail_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::ThumbnailPresenter
  #
  # @see Blacklight::ThumbnailPresenter
  # @see Blacklight::Lens::PresenterBehaviors
  #
  class ThumbnailPresenter < Blacklight::ThumbnailPresenter

    include Blacklight::Lens::PresenterBehaviors

    # TODO: ???

  end

end

__loading_end(__FILE__)

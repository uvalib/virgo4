# app/presenters/blacklight/lens/link_alternate_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::LinkAlternatePresenter
  #
  # @see Blacklight::LinkAlternatePresenter
  # @see Blacklight::Lens::PresenterBehaviors
  #
  class LinkAlternatePresenter < Blacklight::LinkAlternatePresenter

    include Blacklight::Lens::PresenterBehaviors

    # =========================================================================
    # :section: Blacklight::LinkAlternatePresenter overrides
    # =========================================================================

    public

    # URL of the current document.
    #
    # @param [String, Symbol, nil] format   E.g, :pdf.
    #
    # @return [String]
    #
    # @see Blacklight::Lens::SearchState#url_for_document
    #
    # This method overrides:
    # @see Blacklight::LinkAlternatePresenter#href
    #
    def href(format)
      view_context.search_state.url_for_document(document, format: format)
    end

  end

end

__loading_end(__FILE__)

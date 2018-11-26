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

    # The placeholder thumbnail displayed when no thumbnail is available.
    #
    # @type [String]
    #
    DEFAULT_THUMBNAIL = 'no_cover.png'

    # =========================================================================
    # :section: Blacklight::ThumbnailPresenter overrides
    # =========================================================================

    public

    # Render the thumbnail, if available, for a document and link it to the
    # document record.
    #
    # @param [Hash, nil] image_opt    Passed to the image tag.
    # @param [Hash, nil] url_opt      Passed to #link_to_document
    #
    # @option url_options [Boolean] :suppress_link  If *true* display the image
    #                                                 without making it a link.
    #
    # @return [String]
    #
    # This method overrides:
    # @Blacklight::ThumbnailPresenter#thumbnail_tag
    #
    def thumbnail_tag(image_opt = nil, url_opt = nil)
      image_opt ||= {}
      url_opt   ||= {}
      image = thumbnail_value(image_opt)
      if image_opt[:suppress_link] || url_opt[:suppress_link] || image.blank?
        image
      else
        url_opt = url_opt.reverse_merge(tabindex: -1)
        view_context.link_to_document(document, image, url_opt)
      end
    end

    # =========================================================================
    # :section: Blacklight::ThumbnailPresenter overrides
    # =========================================================================

    private

    # The placeholder thumbnail displayed when no thumbnail is available.
    #
    # @return [String]
    #
    # This method overrides:
    # @Blacklight::ThumbnailPresenter#default_thumbnail
    #
    def default_thumbnail
      view_config.default_thumbnail || DEFAULT_THUMBNAIL
    end

  end

end

__loading_end(__FILE__)

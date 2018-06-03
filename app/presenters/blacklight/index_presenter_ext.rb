# app/presenters/blacklight/index_presenter_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::IndexPresenterExt
  #
  # Subclass of:
  # @see Blacklight::IndexPresenter
  #
  class IndexPresenterExt < Blacklight::IndexPresenter

    include Blacklight::PresenterBehaviors

    # =========================================================================
    # :section: Blacklight::IndexPresenter overrides
    # =========================================================================

    public

    # Render the document index heading.
    #
    # @param [Symbol, Proc, String] value
    # @param [Hash, nil]            options
    #
    # @option options [Boolean] :format         Set as *false* for plain text
    #                                             instead of HTML.
    #
    # @option options [Boolean] :show_title     Set as *false* to only show the
    #                                             subtitle.
    #
    # @option options [Boolean] :show_subtitle  Set as *false* to only show the
    #                                             main title.
    #
    # @option options [Boolean] :show_linked_title  Set as *false* to avoid
    #                                             showing the original-language
    #                                             title.
    #
    # @option options [String]  :title_sep      String shown between title and
    #                                             subtitle.  Set as *nil* to
    #                                             have no separator.
    #
    # @option options [String]  :author_sep     String shown between authors.
    #                                             Set as *nil* to have no
    #                                             separator.
    #
    # @option options [String]  :line_break     String shown between title and
    #                                             subtitle.  Set as *nil* to
    #                                             have no break.
    #
    # @return [ActiveSupport::SafeBuffer]   If *format* is *true*.
    # @return [String]                      If *format* is not *true*.
    #
    # TODO: the default field should be `document_show_link_field(doc)'
    #
    # This method overrides:
    # @see Blacklight::IndexPresenter#label
    #
    # For item details (show page), compare with:
    # @see Blacklight::ShowPresenterExt#heading
    #
    # == Usage Notes
    # @see Blacklight::UrlHelperBehaviorExt#link_to_document
    #
    def label(value, options = nil)
      opt = {
        format:              true,
        title_sep:           ': ',
        title_tag:           nil,
        title_class:         nil,
        show_title:          true,
        show_subtitle:       true,
        show_linked_title:   true,
        author_sep:          ', ',
        author_tag:          nil,
        author_class:        nil,
        show_authors:        false,
        show_linked_authors: false,
        line_break:          '<br/>'.html_safe,
      }
      opt.merge!(options) if options.is_a?(Hash)
      format         = opt.delete(:format).presence
      title_sep      = opt.delete(:title_sep).presence
      title_tag      = opt.delete(:title_tag).presence
      title_class    = opt.delete(:title_class).presence
      title          = opt.delete(:show_title).presence
      subtitle       = opt.delete(:show_subtitle).presence
      linked_title   = opt.delete(:show_linked_title).presence
      author_sep     = opt.delete(:author_sep).presence
      author_tag     = opt.delete(:author_tag).presence
      author_class   = opt.delete(:author_class).presence
      authors        = opt.delete(:show_authors).presence
      linked_authors = opt.delete(:show_linked_authors).presence
      line_break     = opt.delete(:line_break).presence
      line_break     = "\n" if line_break && !format

      if value == view_config.title_field

        # Customized handling for the case where the title is being rendered
        # on behalf of the display configuration (@see Config::Catalog).
        # This results in the index entry showing the full title (title and
        # subtitle) followed by the title in the original language.
        default_field = configuration.default_title_field
        title        &&= value_for(view_config.title_field, default_field)
        subtitle     &&= value_for(view_config.subtitle_field)
        linked_title &&= value_for(view_config.alt_title_field)

        title_lines = []
        title_lines << linked_title
        title_lines << [title, subtitle].reject(&:blank?).join(title_sep)

        authors        &&= value_for(view_config.author_field)
        linked_authors &&= value_for(view_config.alt_author_field)

        author_lines = []
        author_lines << Array.wrap(linked_authors).join(author_sep)
        author_lines << Array.wrap(authors).join(author_sep)

        if format
          title_result =
            title_lines.map { |line|
              ERB::Util.h(line) if line.present?
            }.compact.join(line_break).html_safe
          if title_tag || title_class
            title_tag = DEF_TITLE_TAG if title_tag.is_a?(TrueClass)
            title_tag ||= :div
            title_opt = {}
            title_opt[:class] = title_class if title_class
            title_result = content_tag(title_tag, title_result, title_opt)
          end
          author_result =
            author_lines.map { |line|
              ERB::Util.h(line) if line.present?
            }.compact.join(line_break).html_safe
          if author_tag || author_class
            author_tag = DEF_AUTHOR_TAG if author_tag.is_a?(TrueClass)
            author_tag ||= :div
            author_opt = {}
            author_opt[:class] = author_class if author_class
            author_result = content_tag(author_tag, author_result, author_opt)
          end
          title_result + author_result
        else
          (title_lines + author_lines).reject(&:blank?).join(line_break)
        end

      else

        # If there are other situations where this method is called, defer to
        # the original implementation.
        super(value, opt)

      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # view_config
    #
    # @return [Blacklight::Configuration::ViewConfig]
    #
    # Compare with:
    # @see Blacklight::ShowPresenterExt#view_config
    #
    def view_config
      configuration.view_config(:index)
    end

  end

end

__loading_end(__FILE__)

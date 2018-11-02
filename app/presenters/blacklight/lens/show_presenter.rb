# app/presenters/blacklight/lens/show_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::ShowPresenter
  #
  # @see Blacklight::ShowPresenter
  # @see Blacklight::Lens::PresenterBehaviors
  #
  class ShowPresenter < Blacklight::ShowPresenter

    include Blacklight::Lens::PresenterBehaviors

    # =========================================================================
    # :section: Blacklight::ShowPresenter overrides
    # =========================================================================

    public

    # Get the document's "title" to display in the <title> element.
    # (By default, use the #document_heading.)
    #
    # @param [Hash, nil] options
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see self#document_heading
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#html_title
    #
    def html_title(options = nil)
      fields = Array.wrap(view_config.html_title)
      if fields.present?
        field = fields.find { |field| document.has?(field) }
        field ||= configuration.default_title_field
        field_value(field)
      else
        opt = { line_separator: '<br/>'.html_safe }
        opt.merge!(options) if options.is_a?(Hash)
        heading(opt)
      end
    end

    # Get the value of the document's "title_field" and "subtitle_field", or a
    # placeholder value (if empty).
    #
    # @param [Hash, nil] options
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
    # This method overrides:
    # @see Blacklight::ShowPresenter#heading
    #
    # For search results (index page), compare with:
    # @see Blacklight::Lens::IndexPresenter#label
    # TODO: share logic
    #
    def heading(options = nil)
      opt = {
        format:              true,
        title_sep:           ': ',
        title_tag:           DEF_TITLE_TAG,
        title_class:         nil,
        show_title:          true,
        show_subtitle:       true,
        show_linked_title:   true,
        author_sep:          ', ',
        author_tag:          DEF_AUTHOR_TAG,
        author_class:        nil,
        show_authors:        true,
        show_linked_authors: true,
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

      default_field = configuration.default_title_field
      title        &&= value_for(view_config.title_field, default_field)
      subtitle     &&= value_for(view_config.subtitle_field)
      linked_title &&= value_for(view_config.alt_title_field)

      title_lines = []
      title_lines << linked_title
      title_lines << [title, subtitle].reject(&:blank?).join(title_sep)
      title_lines.delete_if(&:blank?).uniq!

      authors        &&= value_for(view_config.author_field)
      linked_authors &&= value_for(view_config.alt_author_field)

      author_lines = []
      author_lines << Array.wrap(linked_authors).join(author_sep)
      author_lines << Array.wrap(authors).join(author_sep)
      author_lines.delete_if(&:blank?).uniq!

      if format
        title_result = title_lines.join(line_break).html_safe
        if title_tag || title_class
          title_tag = DEF_TITLE_TAG if title_tag.is_a?(TrueClass)
          title_tag ||= :div
          title_opt = { itemprop: 'name' }
          title_opt[:class] = title_class if title_class
          title_result = content_tag(title_tag, title_result, title_opt)
        end
        author_result = author_lines.join(line_break).html_safe
        if author_tag || author_class
          author_tag = DEF_AUTHOR_TAG if author_tag.is_a?(TrueClass)
          author_tag ||= :div
          author_opt = {}
          author_opt[:class] = author_class if author_class
          author_result = content_tag(author_tag, author_result, author_opt)
        end
        title_result + author_result
      else
        (title_lines + author_lines).join(line_break)
      end

    end

    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @param [Hash, nil] options
    #
    # @option options [Boolean] :unique   Ensures only one link is output for
    #                                       every content type, e.g. as
    #                                       required by Atom.
    #
    # @option options [Array<String>] :exclude  Array of format shortnames to
    #                                             not include in the output.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def link_rel_alternates(options = nil)
      options ||= {}
      link_alternate_presenter.new(view_context, document, options).render
    end

    # =========================================================================
    # :section: Blacklight::Lens::PresenterBehaviors overrides
    # =========================================================================

    private

    # field_presenter
    #
    # @return [Class] (Blacklight::FieldPresenter or subclass)
    #
    # This method overrides:
    # @see Blacklight::Lens::PresenterBehaviors#field_presenter
    #
    def field_presenter
      @field_presenter ||= configuration&.show&.field_presenter_class || super
    end

    # link_alternate_presenter
    #
    # @return [Class] (Blacklight::LinkAlternatePresenter)
    #
    # This method overrides:
    # @see Blacklight::Lens::PresenterBehaviors#link_alternate_presenter
    #
    def link_alternate_presenter
      @link_alternate_presenter ||=
        configuration&.show&.link_alternate_presenter_class || super
    end

  end

end

__loading_end(__FILE__)

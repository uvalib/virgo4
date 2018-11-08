# app/presenters/blacklight/lens/index_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::IndexPresenter
  #
  # @see Blacklight::IndexPresenter
  # @see Blacklight::Lens::PresenterBehaviors
  #
  class IndexPresenter < Blacklight::IndexPresenter

    include Blacklight::Lens::PresenterBehaviors

    # =========================================================================
    # :section: Blacklight::IndexPresenter overrides
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [Blacklight::Document]      doc
    # @param [Blacklight::Controller]    context
    # @param [Blacklight::Configuration] config
    #
    def initialize(doc, context, config = nil)
      @document      = doc
      @view_context  = context
      @configuration = config || @view_context.blacklight_config
      @view_config   = @configuration.view_config(:index)
    end

    # Render the document index heading.
    #
    # @param [Symbol, Proc, String] value
    # @param [Hash, nil]            options
    #
    # @option options [Boolean] :format         Set as *false* for plain text
    #                                             instead of HTML.
    #
    # @option options [Boolean] :show_title     Set as *false* to only show the
    #                                             original-language title.
    #
    # @option options [Boolean] :show_subtitle  Set as *false* to only show the
    #                                             main title.
    #
    # @option options [Boolean] :show_linked_title  Set as *false* to avoid
    #                                             showing the original-language
    #                                             title.
    #
    # @option options [Boolean] :show_author    Set as *false* to only show the
    #                                             original-language author
    #                                             name(s).
    #
    # @option options [Boolean] :show_linked_author  Set as *false* to avoid
    #                                             showing the original-language
    #                                             author name(s).
    #
    # @option options [String]  :title_sep      String shown between title and
    #                                             subtitle.  Set as *nil* to
    #                                             have no separator.
    #
    # @option options [String]  :author_sep     String shown between authors.
    #                                             Set as *nil* to have no
    #                                             separator.
    #
    # @option options [Numeric] :title_max      Truncate titles longer than
    #                                             this number of characters.
    #
    # @option options [Numeric] :author_max     Truncate titles longer than
    #                                             this number of characters.
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
    # @see Blacklight::Lens::ShowPresenter#heading
    # TODO: share logic
    #
    def label(value, options = nil)

      # If there are other situations where this method is called, defer to the
      # original implementation.
      unless value == view_config.title_field
        return super(value, (options || {}))
      end

      # Customized handling for the case where the title is being rendered on
      # behalf of the display configuration (@see Config::Catalog).
      # This results in the index entry showing the full title (title and
      # subtitle) followed by the title in the original language.
      opt = {
        format:             true,
        line_break:         '<br/>'.html_safe,
        title_sep:          ': ',
        title_max:          nil,
        title_tag:          nil,
        title_class:        nil,
        show_title:         true,
        show_subtitle:      true,
        show_linked_title:  true,
        author_sep:         ', ',
        author_max:         nil,
        author_tag:         nil,
        author_class:       nil,
        show_author:        false,
        show_linked_author: false,
      }
      opt.merge!(options) if options.is_a?(Hash)
      format        = opt[:format].presence
      line_break    = opt[:line_break].presence
      line_break    = "\n" if line_break && !format
      title_sep     = opt[:title_sep].presence
      title_max     = opt[:title_max].presence
      title_tag     = opt[:title_tag].presence
      title_class   = opt[:title_class].presence
      title         = opt[:show_title].presence
      subtitle      = opt[:show_subtitle].presence
      linked_title  = opt[:show_linked_title].presence
      author_sep    = opt[:author_sep].presence
      author_max    = opt[:author_max].presence
      author_tag    = opt[:author_tag].presence
      author_class  = opt[:author_class].presence
      author        = opt[:show_author].presence
      linked_author = opt[:show_linked_author].presence

      def_field      = configuration.default_title_field
      title        &&= value_for(view_config.title_field, def_field).presence
      subtitle     &&= title && value_for(view_config.subtitle_field).presence
      linked_title &&= value_for(view_config.alt_title_field).presence

      title_lines = []
      title_lines << linked_title
      title_lines << [title, subtitle].reject(&:blank?).join(title_sep)
      title_lines.delete_if(&:blank?).uniq!

      author        &&= value_for(view_config.author_field).presence
      linked_author &&= value_for(view_config.alt_author_field).presence

      author_lines = []
      author_lines << Array.wrap(linked_author).join(author_sep)
      author_lines << Array.wrap(author).join(author_sep)
      author_lines.delete_if(&:blank?).uniq!

      if format
        title_lines.map! { |line| ERB::Util.h(line) }
        title_result = title_lines.join(line_break).html_safe
        title_result = title_result.truncate(title_max) if title_max
        if (title_tag || title_class) && title_result.present?
          title_tag = DEF_TITLE_TAG if title_tag.is_a?(TrueClass)
          title_tag ||= :div
          title_opt = {}
          title_opt[:class] = title_class if title_class
          title_result = content_tag(title_tag, title_result, title_opt)
        end
        author_lines.map! { |line| ERB::Util.h(line) }
        author_result = author_lines.join(line_break).html_safe
        author_result = author_result.truncate(author_max) if author_max
        if (author_tag || author_class) && author_result.present?
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
      @field_presenter ||= configuration&.index&.field_presenter_class || super
    end

  end

end

__loading_end(__FILE__)

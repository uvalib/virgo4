# app/presenters/blacklight/lens/concerns/presenter_behaviors.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  # Blacklight::Lens::PresenterBehaviors
  #
  # Methods common to presenters.
  #
  module PresenterBehaviors

    include Blacklight::Lens

    DEF_TITLE_TAG  = :h1
    DEF_AUTHOR_TAG = :h4

    # =========================================================================
    # :section: Blacklight::IndexPresenter/ShowPresenter overrides
    # =========================================================================

    public

    # Render a field value.
    #
    # @param [String, Symbol, Blacklight::Configuration::Field] field
    # @param [Hash, nil] opt
    #
    # @option opt [Boolean] :raw
    # @option opt [String]  :value
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#field_value
    # @see Blacklight::IndexPresenter#field_value
    #
    def field_value(field, opt = nil)
      unless field.is_a?(Blacklight::Configuration::Field)
        field = field_config(field)
      end
      field_values(field, opt)
    end

    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_facet
    #
    # @param [Blacklight::Configuration::Field] config
    # @param [Hash, nil]                        options
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#field_values
    # @see Blacklight::IndexPresenter#field_values
    #
    def field_values(config, options = nil)
      options ||= {}
      field_presenter.new(view_context, document, config, options).render
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the value of the document's "title_field" and "subtitle_field", or a
    # placeholder value (if empty).
    #
    # @param [Hash, nil] options
    #
    # @option options [Boolean] :show           Set as *true* for variations
    #                                             appropriate for show pages.
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
    # @see Blacklight::Lens::ShowPresenter#heading
    # @see Blacklight::Lens::IndexPresenter#label
    #
    def item_heading(options = nil)

      options ||= {}
      show_page = options[:show].present?
      opt = {
        format:             true,
        line_break:         '<br/>'.html_safe,
        title_sep:          ': ',
        title_max:          nil,
        title_tag:          (DEF_TITLE_TAG if show_page),
        title_class:        nil,
        show_title:         true,
        show_subtitle:      true,
        show_linked_title:  true,
        author_sep:         ', ',
        author_max:         nil,
        author_tag:         (DEF_AUTHOR_TAG if show_page),
        author_class:       'document-author',
        show_author:        show_page,
        show_linked_author: show_page,
      }
      opt.merge!(options)

      format       = opt[:format].presence
      line_break   = opt[:line_break].presence
      line_break   = "\n" if line_break && format.nil?
      title_sep    = opt[:title_sep].presence
      title_max    = opt[:title_max].presence
      title_tag    = opt[:title_tag].presence
      title_class  = opt[:title_class].presence
      title        = opt[:show_title].presence
      subtitle     = opt[:show_subtitle].presence
      alt_title    = opt[:show_linked_title].presence
      author_sep   = opt[:author_sep].presence
      author_max   = opt[:author_max].presence
      author_tag   = opt[:author_tag].presence
      author_class = opt[:author_class].presence
      author       = opt[:show_author].presence
      alt_author   = opt[:show_linked_author].presence

      title     &&= value_for(view_config.title_field).presence
      subtitle  &&= title && value_for(view_config.subtitle_field).presence
      alt_title &&= value_for(view_config.alt_title_field).presence

      title_lines = []
      title_lines << alt_title
      title_lines << [title, subtitle].reject(&:blank?).join(title_sep)
      title_lines.delete_if(&:blank?).uniq!
      title_lines << title_missing if title_lines.blank?

      # Eliminate the configured line-oriented separator options for #value_for
      # if author_sep is not an HTML element.
      vf = {}
      if author_sep && !author_sep.html_safe?
        vf[:separator_options] = { words_connector: author_sep }
      end
      author_lines = []
      author_lines << value_for(view_config.alt_author_field, vf) if alt_author
      author_lines << value_for(view_config.author_field, vf)     if author
      author_lines.delete_if(&:blank?).uniq!

      if format
        title_lines.map! { |line| ERB::Util.h(line) }
        title_result = title_lines.join(line_break).html_safe
        title_result = title_result.truncate(title_max) if title_max
        if (title_tag || title_class) && title_result.present?
          title_tag = DEF_TITLE_TAG if title_tag.is_a?(TrueClass)
          title_tag ||= :div
          title_opt = show_page ? { itemprop: 'name' } : {}
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

    # Title to show when the data does not include a title of any kind.
    #
    # @return [String]
    #
    def title_missing
      "(no title) - #{document.id}"
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # field_presenter
    #
    # @return [Class] (Blacklight::FieldPresenter or subclass)
    #
    def field_presenter
      configuration&.field_presenter_class ||
        Blacklight::Lens::FieldPresenter
    end

    # link_alternate_presenter
    #
    # @return [Class] (Blacklight::LinkAlternatePresenter)
    #
    # @see Blacklight::Lens::PresenterBehaviors#field_presenter
    #
    def link_alternate_presenter
      configuration&.link_alternate_presenter_class ||
        Blacklight::Lens::LinkAlternatePresenter
    end

    # value_for
    #
    # @param [Symbol, Array<Symbol>] fields
    # @param [Symbol, Hash, nil]     opt
    #
    # @return [String, nil]
    #
    def value_for(fields, opt = nil)
      fv_opt, alt_field = opt.is_a?(Hash) ? [opt, nil] : [nil, opt]
      field = Array.wrap(fields).find { |f| document.has?(f) } || alt_field
      return unless field.present?
      fv_opt ||= {}
      field_value(field, fv_opt.merge(value: document[field]))
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # A minimal implementation that is defined only if the current context does
    # not already have :content_tag.
    #
    # @param [Symbol, String] tag
    # @param [String]         value
    # @param [Hash, nil]      opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def content_tag(tag, value = nil, opt = nil)
      if value.is_a?(Hash)
        opt   = value
        value = (yield if block_given?)
      end
      value = ERB::Util.h(value) if value.present?
      attr =
        if opt.is_a?(Hash)
          opt.map { |k, v|
            %Q(#{ERB::Util.h(k)}="#{ERB::Util.h(v)}") unless k.nil? || v.nil?
          }.compact.join(' ')
        end
      attr = ' ' + attr if attr.present?
      "<#{tag}#{attr}>#{value}</#{tag}>".html_safe
    end unless defined?(content_tag)

  end

end

__loading_end(__FILE__)

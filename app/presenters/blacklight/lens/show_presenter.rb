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
    # @return [ActiveSupport::SafeBuffer]   If *options[:format]* is *true*.
    # @return [String]                      Otherwise.
    #
    # @see Blacklight::Lens::PresenterBehaviors#item_heading
    #
    # This method overrides:
    # @see Blacklight::ShowPresenter#heading
    #
    def heading(options = nil)
      item_heading((options || {}).merge(show: true))
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

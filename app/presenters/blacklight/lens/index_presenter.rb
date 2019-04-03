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
    # This method uses customized handling for the case where the title is
    # being rendered on behalf of the display configuration.  This results in
    # the index entry showing the full title (title and subtitle) followed by
    # the title in the original language.
    #
    # In other cases where this method is called it defers to the Blacklight
    # implementation.
    #
    # @param [Symbol]    value
    # @param [Hash, nil] options
    #
    # @return [ActiveSupport::SafeBuffer]   If *options[:format]* is *true*.
    # @return [String]                      Otherwise.
    #
    # @see Blacklight::Lens::PresenterBehaviors#item_heading
    #
    # This method overrides:
    # @see Blacklight::IndexPresenter#label
    #
    def label(value, options = nil)
      value = value.to_s.to_sym unless value.is_a?(Symbol)
      if value == view_config.title_field.to_sym
        item_heading(options)
      else
        super(value, (options || {}))
      end
    end

    # =========================================================================
    # :section: Blacklight::Lens::PresenterBehaviors overrides
    # =========================================================================

    public

    # Render availability information.
    #
    # If there was an error getting availability information, rescue here to
    # prevent displaying the rest of the search results on the page.
    #
    # @param [Symbol]                status   Default is from `document`.
    # @param [TrueClass, FalseClass] format   Default: *true*
    # @param [Symbol]                mode     Default: :tabular
    #
    # @return [ActiveSupport::SafeBuffer]  If *format* is *true*.
    # @return [String]                     If *format* is *false*.
    # @return [nil]                        If missing document or availability.
    #
    # This method overrides:
    # @see Blacklight::Lens::PresenterBehaviors#availability
    #
    def availability(status: nil, format: true, mode: :tabular)

      status ||= document&.availability_status
      label = super(status: status, format: format)
      return if label.blank?
      return label unless format

      av = document.availability

      lines =
        case status
          when :available, :mixed then av.library_locations_available
          when :unavailable       then av.library_locations_unavailable
        end

      locations =
        content_tag(:table, class: "shelf-locations #{mode}".squish) do
          if lines
            separator = content_tag(:td, '-', class: 'separator')
            lines.map { |lib, loc|
              content_tag(:tr, class: 'line') do
                lib = content_tag(:td, lib, class: 'library')
                loc =
                  content_tag(:td, class: 'locations') do
                    if mode == :tabular
                      loc.map { |v| content_tag(:div, v) }.join.html_safe
                    else
                      loc.join(', ')
                    end
                  end
                [lib, separator, loc].compact.join.html_safe
              end
            }.join("\n").html_safe
          else
            content_tag(:tr, class: 'line') do
              content_tag(:td, class: 'error') do
                av.error_message || 'Unknown error'
              end
            end
          end
        end

      content_tag(:div, class: 'availability-status') do
        label + locations
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

# app/presenters/blacklight/lens/field_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::FieldPresenter
  #
  # @see Blacklight::FieldPresenter
  # @see Blacklight::Lens::PresenterBehaviors
  #
  class FieldPresenter < Blacklight::FieldPresenter

    include Blacklight::Lens::PresenterBehaviors

    # =========================================================================
    # :section: Blacklight::FieldPresenter overrides
    # =========================================================================

    public

    # Produce field values.
    #
    # If the instance was initialized with `raw: true` then the field values
    # will be returned directly without going through Rendering::Pipeline.
    #
    # @return [Array]
    #
    # This method overrides:
    # @see Blacklight::FieldPresenter#render
    #
    def render
      if options[:raw]
        retrieve_values
      else
        options[:value] &&= Array.wrap(options[:value]).map(&:html_safe)
        if options.key?(:separator_options)
          @field_config = @field_config.dup
          @field_config.separator_options = options[:separator_options]
        end
        super
      end
    end

    # =========================================================================
    # :section: Blacklight::FieldPresenter overrides
    # =========================================================================

    private

    # Retrieve field values.
    #
    # @return [Array]
    #
    # This method overrides:
    # @see Blacklight::FieldPresenter#retrieve_values
    #
    def retrieve_values
      Blacklight::Lens::FieldRetriever.new(
        document,
        field_config,
        options
      ).fetch
    end

  end

end

__loading_end(__FILE__)

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
    # == Implementation Notes
    # For option[:raw], it is assumed that the target output format is JSON
    # which is intended for AJAX manipulation, so :helper_method is explicitly
    # invoked in order to process the field accordingly.  This means that
    # helper methods must be aware of the request format so that they can emit
    # the proper results.
    #
    # This method overrides:
    # @see Blacklight::FieldPresenter#render
    #
    def render
      if options[:raw].blank?
        options[:value] &&= Array.wrap(options[:value]).map(&:html_safe)
        if options.key?(:separator_options)
          @field_config = @field_config.dup
          @field_config.separator_options = options[:separator_options]
        end
        super
      elsif @field_config.helper_method
        opt = options
        opt = opt.merge(value: retrieve_values) unless opt[:value].present?
        controller.view_context.send(@field_config.helper_method, opt)
      else
        retrieve_values
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
      field_retriever.new(document, field_config, options).fetch
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The configured field retriever.
    #
    # @return [Class]                 Default: Blacklight::Lens::FieldRetriever
    #
    def field_retriever
      options[:blacklight_config]&.field_retriever_class ||
        Blacklight::Lens::FieldRetriever
    end

  end

end

__loading_end(__FILE__)

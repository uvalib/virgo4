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
    # @see Blacklight::IndexPresenter#field_values
    # @see Blacklight::ShowPresenter#field_values
    #
    def field_values(config, options = nil)
      options ||= {}
      field_presenter.new(view_context, document, config, options).render
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
    # @param [Symbol, nil]           alt_field
    #
    # @return [String, nil]
    #
    # Compare with:
    # @see Blacklight::Lens::ShowPresenter#value_for
    #
    def value_for(fields, alt_field = nil)
      field = Array.wrap(fields).find { |f| document.has?(f) } || alt_field
      field_value(field, value: document[field]) if field
    end

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

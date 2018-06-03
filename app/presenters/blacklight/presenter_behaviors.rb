# app/presenters/blacklight/presenter_behaviors.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::PresenterBehaviors
  #
  # Methods common to presenters.
  #
  module PresenterBehaviors

    DEF_TITLE_TAG  = :h1
    DEF_AUTHOR_TAG = :h4

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # value_for
    #
    # @param [Symbol, Array<Symbol>] fields
    # @param [Symbol, nil]           alt_field
    #
    # @return [String, nil]
    #
    # Compare with:
    # @see Blacklight::ShowPresenterExt#value_for
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

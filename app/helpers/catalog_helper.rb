# app/helpers/catalog_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replaces the Blacklight module with local behavior definitions.
#
module CatalogHelper

  include Blacklight::CatalogHelperBehaviorExt

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  public

  # format_facet_label
  #
  # @param [Hash] options             Supplied by Blacklight::FieldPresenter.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # @see ArticlesHelper#eds_publication_type_label
  # @see Blacklight::Rendering::HelperMethod#render_helper
  #
  def format_facet_label(options = nil)
    values = (options[:value] if options.is_a?(Hash))
    return unless values.present?
    Array.wrap(values).map { |value|
      content_tag(:span, value, class: 'label label-default') if value.present?
    }.compact.join("&nbsp;\n").html_safe
  end

end

__loading_end(__FILE__)

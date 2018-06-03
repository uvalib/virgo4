# app/helpers/blacklight/search_history_constraints_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::SearchHistoryConstraintsHelperBehaviorExt
#
# @see Blacklight::SearchHistoryConstraintsHelperBehavior
#
module Blacklight::SearchHistoryConstraintsHelperBehaviorExt

  include Blacklight::SearchHistoryConstraintsHelperBehavior
  include LensHelper

  # ===========================================================================
  # :section: Blacklight::SearchHistoryConstraintsHelperBehavior overrides
  # ===========================================================================

  public

  # Render the search query constraint.
  #
  # @param [ActionController::Parameters, Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_q
  #
  def render_search_to_s_q(params)
    query = params[:q]
    return ''.html_safe unless query.present?
    search = params[:search_field].to_s.presence
    if search
      skipped = [default_search_field.key.to_s]
      skipped << blacklight_config.advanced_search.url_key.to_s
      search  = nil if skipped.map(&:to_s).include?(search)
    end
    label = (search && label_for_search_field(search)) || ''
    value = render_filter_value(query)
    render_search_to_s_element(label, value)
  end

  # Render the search facet constraints.
  #
  # @param [ActionController::Parameters, Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_filters
  #
  def render_search_to_s_filters(params)
    connector = t('blacklight.and', default: 'AND')
    connector = content_tag(:span, " #{connector} ", class: 'filterSeparator')
    facets = params[:f] || {}
    facets.map { |field, values|
      label = facet_field_label(field)
      value =
        values.map { |value|
          render_filter_value(value, field)
        }.join(connector).html_safe
      render_search_to_s_element(label, value)
    }.join("\n").html_safe
  end

end

__loading_end(__FILE__)

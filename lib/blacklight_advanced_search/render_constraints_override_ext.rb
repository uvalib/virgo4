# lib/blacklight_advanced_search/render_constraints_override_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Meant to be applied on top of Blacklight view helpers, to override certain
# methods from RenderConstraintsHelper (newish in BL), to effect constraints
# rendering and search history rendering.
#
# @see BlacklightAdvancedSearch::RenderConstraintsOverride
#
# == Implementation Notes
# If the original Blacklight Advanced Search module were "included" as the
# basis for this implementation, then none of the methods here could use
# "super" because that would refer to the original Blacklight Advanced Search
# method rather than the method that is being overridden.
#
# For that reason, this module can't use
# "include BlacklightAdvancedSearch::RenderConstraintsOverride" and has to
# define all of the methods itself.
#
module BlacklightAdvancedSearch::RenderConstraintsOverrideExt

  # Needed for RubyMine to indicate overrides.
  unless ONLY_FOR_DOCUMENTATION
    include Blacklight::RenderConstraintsHelperBehaviorExt
    include Blacklight::FacetsHelperBehavior
    include Blacklight::SearchHistoryConstraintsHelperBehaviorExt
    include BlacklightAdvancedSearch::RenderConstraintsOverride
  end

  include LensHelper

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::RenderConstraintsOverride replacements
  #           of dynamic::RenderConstraintsHelperBehavior overrides
  # ===========================================================================

  public

  # query_has_constraints?
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#query_has_constraints?
  #
  # During operation this method overrides:
  # @see Blacklight::RenderConstraintsHelperBehaviorExt#query_has_constraints?
  #
  def query_has_constraints?(req_params = nil)
    req_params ||= params
    %i(q f f_inclusive).any? { |field| req_params[field].present? }
  end

  # Override of Blacklight method, provide advanced constraints if needed,
  # otherwise call super.
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#render_constraints_query
  #
  # During operation this method overrides:
  # @see Blacklight::RenderConstraintsHelperBehaviorExt#render_constraints_query
  #
  def render_constraints_query(req_params = nil)
    req_params ||= params
    # Standard search constraints.
    result = super(req_params)
    # Advanced search constraints.
    qp = advanced_query(req_params)
    if qp&.keyword_queries&.present?
      queries =
        qp.keyword_queries.map { |field, query|
          label = label_for_search_field(field)
          path  = remove_advanced_keyword_query(field, req_params)
          opt   = { remove: path.except(:controller, :action) }
          render_constraint_element(label, query, opt)
        }.join("\n").html_safe
      if qp.keyword_queries.size > 1
        op = qp.keyword_op
        any_of = t("blacklight_advanced_search.op.#{op}.filter_label")
        any_of.capitalize!
        queries =
          content_tag(:span, class: 'inclusive_or appliedFilter well') do
            content_tag(:span, any_of, class: 'operator') << "\n" << queries
          end
      end
      result << "\n" unless result.blank?
      result << queries
    end
    result
  end

  # Override of Blacklight method, provide advanced constraints if needed,
  # otherwise call super.
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#render_constraints_query
  #
  # During operation this method overrides:
  # @see Blacklight::RenderConstraintsHelperBehaviorExt#render_constraints_filters
  #
  def render_constraints_filters(req_params = nil)
    req_params ||= params
    # Standard search constraints.
    result = [super(req_params)]
    # Advanced search constraints.
    qp = advanced_query(req_params)
    if qp&.filters&.present?
      op_options = { class: 'text-muted constraint-connector' }
      connector  = content_tag(:strong, filter_connector, op_options)
      result +=
        qp.filters.map do |field, values|
          label  = facet_field_label(field)
          values = safe_join(Array.wrap(values), connector)
          path   = remove_advanced_filter_group(field, req_params)
          opt    = { remove: path.except(:controller, :action) }
          render_constraint_element(label, values, opt)
        end
    end
    result.delete_if(&:blank?)
    safe_join(result, "\n")
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::RenderConstraintsOverride replacements
  #           of dynamic Blacklight::FacetsHelperBehavior overrides
  # ===========================================================================

  public

  # Override of Blacklight method, so our inclusive facet selections are still
  # recognized for eg highlighting facet with selected values.
  #
  # @param [String, Symbol] field
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#facet_field_in_params?
  #
  # During operation this method overrides:
  # @see Blacklight::FacetsHelperBehavior#facet_field_in_params?
  #
  def facet_field_in_params?(field)
    super || query_parser.filters.keys.include?(field)
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::RenderConstraintsOverride replacements
  #           of dynamic Blacklight::SearchHistoryConstraintsHelperBehavior
  #           overrides
  # ===========================================================================

  public

  # render_search_to_s_filters
  #
  # @param [Hash] req_params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#render_search_to_s_filters
  #
  # During operation this method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_filters
  #
  def render_search_to_s_filters(req_params)
    # Standard :f facets.
    result = [super(req_params)]
    # Advanced :f_inclusive facets.
    qp = query_parser(req_params)
    result +=
      qp.filters.map do |field, values|
        label  = facet_field_label(field)
        values = values.keys if values.is_a?(Hash) # Old-style.
        values = values.join(" #{filter_connector} ")
        render_search_to_s_element(label, values)
      end
    result.delete_if(&:blank?)
    safe_join(result, "\n")
  end

  # render_search_to_s_q
  #
  # @param [Hash] req_params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#render_search_to_s_q
  #
  # During operation this method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_q
  #
  def render_search_to_s_q(req_params)
    # Standard searches.
    result = [super(req_params)]
    # Advanced :search_field searches.
    qp = query_parser(req_params)
    op = qp.keyword_op
    if (qp.keyword_queries.size > 1) && (op == 'OR')
      # Need to do something to make the inclusive-or search clear.
      any_of = t("blacklight_advanced_search.op.#{op}.filter_label")
      any_of.capitalize!
      queries =
        qp.keyword_queries.map { |field, query|
          key_label = label_for_search_field(field)
          h("#{key_label}: #{query}")
        }.join(' ; ').html_safe
      result << render_search_to_s_element(any_of, queries)
    else
      result +=
        qp.keyword_queries.map do |field, query|
          key_label = label_for_search_field(field)
          render_search_to_s_element(key_label, query)
        end
    end
    result.delete_if(&:blank?)
    safe_join(result, "\n")
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::RenderConstraintsOverride replacements
  # ===========================================================================

  public

  # remove_advanced_keyword_query
  #
  # @param [String, Symbol]                          field
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [Hash]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#remove_advanced_keyword_query
  #
  def remove_advanced_keyword_query(field, req_params = nil)
    params_hash(req_params).tap { |result| result.delete(field) }
  end

  # remove_advanced_filter_group
  #
  # @param [String, Symbol]                          field
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [Hash]
  #
  # This method replaces:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#remove_advanced_filter_group
  #
  def remove_advanced_filter_group(field, req_params = nil)
    params_hash(req_params).tap do |result|
      if result[:f_inclusive]&.include?(field)
        result[:f_inclusive] = result[:f_inclusive].dup
        result[:f_inclusive].delete(field)
        result.delete(:f_inclusive) if result[:f_inclusive].empty?
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # query_parser
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [BlacklightAdvancedSearch::QueryParserExt]
  #
  # NOTE: Is this not the same as:
  # @see BlacklightAdvancedSearch::ControllerExt#advanced_query
  #
  def query_parser(req_params = nil)
    req_params ||= params
    BlacklightAdvancedSearch::QueryParserExt.new(req_params, blacklight_config)
  end

  # params_hash
  #
  # @param [ActionController::Parameters, Hash, nil] req_params  Def: `params`.
  #
  # @return [Hash]
  #
  def params_hash(req_params = nil)
    req_params ||= params
    Blacklight::SearchStateExt.new(req_params, blacklight_config).to_h
  end

  # Return the localized string for the logical connector displayed between
  # filter values.
  #
  # @param [String, nil] op           Default: 'OR'.
  #
  # @return [String]
  #
  def filter_connector(op = nil)
    op ||= 'OR'
    t("blacklight.#{op.downcase}", default: op).upcase
  end

end

__loading_end(__FILE__)

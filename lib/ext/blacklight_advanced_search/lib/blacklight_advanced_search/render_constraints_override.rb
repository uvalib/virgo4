# lib/ext/blacklight_advanced_search/lib/blacklight_advanced_search/render_constraints_override.rb
#
# Inject BlacklightAdvancedSearch::RenderConstraintsOverride extensions and
# replacement methods.

__loading_begin(__FILE__)

require 'blacklight_advanced_search/render_constraints_override'

# Override BlacklightAdvancedSearch definitions.
#
# @see BlacklightAdvancedSearch::RenderConstraintsOverride
#
module BlacklightAdvancedSearch::RenderConstraintsOverrideExt

  include Blacklight::Lens::SearchFields

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::RenderConstraintsOverride overrides
  # ===========================================================================

  public

  # Render the search query constraint.
  #
  # @param [ActionController::Parameters, Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#render_search_to_s_q
  #
  # Compare with:
  # @see SearchHistoryConstraintsHelper#render_search_to_s_q
  #
  def render_search_to_s_q(params)
    content = super(params)
    adv = BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config)
    if (adv_queries = adv.keyword_queries).present?
      content <<
        if (adv_queries.size > 1) && (adv.keyword_op == 'OR')
          # Need to do something to make the inclusive-or search clear.
          values =
            adv_queries.map { |field, query|
              label = search_field_def_for_key(field)[:label]
              h("#{label}: #{query}")
            }.join(' ; ').html_safe
          label = t('blacklight_advanced_search.op.OR.filter_label').capitalize
          render_search_to_s_element(label, values, escape_value: false)
        else
          adv_queries.map { |field, query|
            label = search_field_def_for_key(field)[:label]
            render_search_to_s_element(label, query)
          }.join('').html_safe
        end
    end
    content
  end

  # Render the search facet constraints.
  #
  # @param [ActionController::Parameters, Hash] params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::RenderConstraintsOverride#render_search_to_s_filters
  #
  # Compare with:
  # @see SearchHistoryConstraintsHelper#render_search_to_s_filters
  #
  def render_search_to_s_filters(params)
    adv = BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config)

    # === AND'ed filters
    content =
      adv.exclusive_filters.map { |field, values|
        label  = facet_field_label(field)
        values = values.map { |value| render_filter_value(value, field) }
        values = values.join(and_operator).html_safe
        render_search_to_s_element(label, values)
      }

    # === OR'ed filters
    content +=
      adv.filters.map { |field, values|
        # Skip filters that will have been handled above.
        next if values.size <= 1
        label  = facet_field_label(field)
        values = values.keys if values.is_a?(Hash) # Old-style; still a thing?
        values = values.join(or_operator).html_safe
        render_search_to_s_element(label, values)
      }

    content.reject(&:blank?).join("\n").html_safe
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

# For "super" to work as intended from the override of :render_search_to_s_q
# we have to eliminate the method defined in the original module.  Otherwise,
# "super" will refer to that method definition and not the one further along
# the ancestor chain.
BlacklightAdvancedSearch::RenderConstraintsOverride.send(
  :remove_method, :render_search_to_s_q
)

override BlacklightAdvancedSearch::RenderConstraintsOverride =>
         BlacklightAdvancedSearch::RenderConstraintsOverrideExt

__loading_end(__FILE__)

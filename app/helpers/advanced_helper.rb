# app/helpers/advanced_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Helper methods for the advanced search form.
#
# @see BlacklightAdvancedSearch::AdvancedHelperBehavior
#
module AdvancedHelper

  include BlacklightAdvancedSearch::AdvancedHelperBehavior
  include SearchHistoryConstraintsHelper
  include LensHelper

  def self.included(base)
    __included(base, '[AdvancedHelper]')
  end

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedHelperBehavior overrides
  # ===========================================================================

  public

  # select_menu_for_field_operator
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::AdvancedHelperBehavior#select_menu_for_field_operator
  #
  def select_menu_for_field_operator
    options = {
      t('blacklight_advanced_search.op.AND.menu_label') => 'AND',
      t('blacklight_advanced_search.op.OR.menu_label')  => 'OR'
    }.sort
    options = options_for_select(options, params[:op])
    select_tag(:op, options, class: 'input-small')
  end

end

__loading_end(__FILE__)

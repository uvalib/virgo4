# app/helpers/blacklight_advanced_search/advanced_search_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module BlacklightAdvancedSearch

  # BlacklightAdvancedSearch::AdvancedHelperBehaviorExt
  #
  # @see BlacklightAdvancedSearch::AdvancedHelperBehavior
  #
  module AdvancedHelperBehaviorExt

    include BlacklightAdvancedSearch::AdvancedHelperBehavior
    include LensHelper

    # =========================================================================
    # :section: BlacklightAdvancedSearch::AdvancedHelperBehavior overrides
    # =========================================================================

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

end

__loading_end(__FILE__)

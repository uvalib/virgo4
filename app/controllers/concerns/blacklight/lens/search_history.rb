# app/controllers/concerns/blacklight/lens/search_history.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Compare with:
# @see Blacklight::SearchHistory
#
# == Implementation Notes
# This does not include Blacklight::SearchHistory to avoid executing its
# `included` block -- which means that it has to completely recreate the
# module.
#
module Blacklight::Lens::SearchHistory

  extend ActiveSupport::Concern

  # Needed for RubyMine to indicate overrides.
  include Blacklight::SearchHistory unless ONLY_FOR_DOCUMENTATION

  included do |base|
    __included(base, 'Blacklight::Lens::SearchHistory')
  end

  # ===========================================================================
  # :section: Blacklight::SearchHistory replacements
  # ===========================================================================

  public

  # == GET /search_history
  #
  # This method replaces:
  # @see Blacklight::SearchHistory#index
  #
  # Compare with:
  # @see Blacklight::Lens::SavedSearches#index
  #
  def index
    @searches = searches_from_history
    respond_to do |format|
      format.html { }
      format.json { @presenter = json_presenter(@searches) }
    end
  end

  # == DELETE /search_history/clear
  #
  # This method replaces:
  # @see Blacklight::SearchHistory#clear
  #
  # Compare with:
  # @see Blacklight::Lens::SavedSearches#clear
  #
  def clear
    if session[:history].clear
      flash[:notice] = I18n.t('blacklight.search_history.clear.success')
    else
      flash[:error]  = I18n.t('blacklight.search_history.clear.failure')
    end
    go_back(fallback: blacklight.search_history_path)
  end

end

__loading_end(__FILE__)

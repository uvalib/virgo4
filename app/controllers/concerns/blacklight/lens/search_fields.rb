# app/controllers/concerns/blacklight/lens/search_fields.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Compare with:
# @see Blacklight::SearchFields
#
module Blacklight::Lens::SearchFields

  extend ActiveSupport::Concern

  include Blacklight::SearchFields
  include Blacklight::Lens

  included do |base|
    __included(base, 'Blacklight::Lens::SearchFields')
  end

  # ===========================================================================
  # :section: Blacklight::SearchFields overrides
  # ===========================================================================

  public

  # Looks up search field config list from blacklight_config[:search_fields],
  # and 'normalizes' all field config hashes using normalize_config method.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Blacklight::Configuration::SearchField>]
  #
  # This method overrides:
  # @see Blacklight::SearchFields#search_field_list
  #
  def search_field_list(lens = nil)
    blacklight_config_for(lens).search_fields.values
  end

  # Returns the search field marked as default, or the first field if none was
  # marked as default.
  #
  # Use for simpler display in history, etc.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Blacklight::Configuration::SearchField]
  #
  # @see self#search_field_list
  #
  # This method overrides:
  # @see Blacklight::SearchFields#default_search_field
  #
  def default_search_field(lens = nil)
    blacklight_config_for(lens).default_search_field
  end

  # ===========================================================================
  # :section: Blacklight 7 transition
  # ===========================================================================

  public

  # Looks up a search field blacklight_config hash from search_field_list
  # having a certain supplied :key.
  #
  # @param [Symbol, String] key
  # @param [Object, nil]    lens      Default: `current_lens`.
  #
  # @return [Blacklight::Configuration::SearchField, nil]
  #
  # == Implementation Notes
  # This method has been removed in Blacklight 7, but the currently-available
  # version of Blacklight Advanced Search still uses it.
  #
  def search_field_def_for_key(key, lens = nil)
    blacklight_config_for(lens).search_fields[key.to_s]
  end

end

__loading_end(__FILE__)

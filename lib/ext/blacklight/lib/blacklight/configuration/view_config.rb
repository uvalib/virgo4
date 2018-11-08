# lib/ext/blacklight/lib/blacklight/configuration/view_config.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/configuration'
require 'blacklight/configuration/view_config'
require 'blacklight/lens'

# Override Blacklight definitions.
#
# @see Blacklight::Configuration::ViewConfig
#
module Blacklight::Configuration::ViewConfigExt

  # Return the configured label for the current field definition.
  #
  # @param [String, Symbol] view
  # @param [Symbol, nil]    lens
  #
  # @return [String]
  #
  # Compare with:
  # @see Blacklight::ConfigurationHelperBehavior#view_label
  #
  def display_label(view, lens = nil)
    lens = Blacklight::Lens.key_for(lens)
    keys = []
    keys << :"blacklight.#{lens}.search.view_title"   if lens
    keys << :"blacklight.#{lens}.search.view.#{view}" if lens
    keys << :'blacklight.search.view_title'
    keys << :"blacklight.search.view.#{view}"
    keys << label
    keys << title
    keys << view.to_s.titleize
    keys.delete_if(&:blank?)
    field_label(*keys)
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Configuration::ViewConfig =>
         Blacklight::Configuration::ViewConfigExt

__loading_end(__FILE__)

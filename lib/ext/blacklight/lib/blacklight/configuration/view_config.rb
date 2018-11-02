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

override Blacklight::Configuration::ViewConfig do

  # Return the configured label for the current field definition.
  #
  # @param [String, Symbol] view
  # @param [Symbol, nil]    lens
  #
  # @return [String]
  #
  def display_label(view, lens = nil)
    lens = Blacklight::Lens.key_for(lens)
    keys = []
    keys << :"blacklight.#{lens}.search.view_title.#{view}" if lens
    keys << :"blacklight.#{lens}.search.view.#{view}"       if lens
    keys << :"blacklight.search.view_title.#{view}"
    keys << :"blacklight.search.view.#{view}"
    keys << title
    keys << view.to_s.titleize
    keys.delete_if(&:blank?)
    I18n.translate(label, default: keys)
  end

end

__loading_end(__FILE__)

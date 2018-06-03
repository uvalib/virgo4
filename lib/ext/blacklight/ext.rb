# lib/ext/blacklight/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/lens'

# Load files from this subdirectory.
_LIB_EXT_BLACKLIGHT_LOADS ||=
  Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].each do |path|
    require(path) unless path == __FILE__
  end

__loading_end(__FILE__)

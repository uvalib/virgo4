# lib/ext/ebsco-eds/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the EBSCO EDS gem.

__loading_begin(__FILE__)

require File.join(Rails.root, 'app/models/blacklight/eds')

# Load files from this subdirectory.
_LIB_EXT_EBSCO_EDS_LOADS ||=
  Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].each do |path|
    require(path) unless path == __FILE__
  end

__loading_end(__FILE__)

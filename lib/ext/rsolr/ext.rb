# lib/ext/rsolr/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Item caching for Solr.

__loading_begin(__FILE__)

require 'rsolr'

# Load files from this subdirectory.
_LIB_EXT_RSOLR_LOADS ||=
  Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].each do |path|
    require(path) unless path == __FILE__
  end

__loading_end(__FILE__)

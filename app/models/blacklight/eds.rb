# app/models/blacklight/eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'ebsco/eds'

module Blacklight
  module Eds
    autoload :Repository,       'blacklight/eds/repository'
    autoload :SuggestSearchEds, 'blacklight/eds/suggest_search_eds'
  end
end

__loading_end(__FILE__)

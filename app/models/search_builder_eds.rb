# app/models/search_builder_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search_builder'
require 'blacklight/eds/search_builder_behavior'

# SearchBuilderEds
#
# @see SearchBuilder
# @see Blacklight::Eds::SearchBuilderBehavior
#
class SearchBuilderEds < ::SearchBuilder
  include Blacklight::Eds::SearchBuilderBehavior
end

__loading_end(__FILE__)

# lib/blacklight/lens/search_builder_behavior.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight/solr/search_builder_behavior'

module Blacklight::Lens

  # Blacklight::Lens::SearchBuilderBehavior
  #
  # @see Blacklight::Solr::SearchBuilderBehavior
  #
  module SearchBuilderBehavior

    extend ActiveSupport::Concern

    include Blacklight::Solr::SearchBuilderBehavior

    included do |base|
      __included(base, 'Blacklight::Lens::SearchBuilderBehavior')
    end

    # TODO: ???

  end

end

__loading_end(__FILE__)

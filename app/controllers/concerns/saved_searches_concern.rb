# app/controllers/concerns/saved_searches_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SavedSearchesConcern
#
module SavedSearchesConcern

  extend ActiveSupport::Concern

  include BlacklightAdvancedSearch::Controller
  include Blacklight::Lens::SavedSearches

  included do |base|
    __included(base, 'SavedSearchesConcern')
  end

end

__loading_end(__FILE__)

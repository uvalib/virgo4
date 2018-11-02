# app/controllers/concerns/articles_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/articles'

# ArticlesConcern
#
module ArticlesConcern

  extend ActiveSupport::Concern

  include Blacklight::Eds::Controller
  include Blacklight::Eds::Catalog
  include EdsConcern

  included do |base|
    __included(base, 'ArticlesConcern')
  end

end

__loading_end(__FILE__)

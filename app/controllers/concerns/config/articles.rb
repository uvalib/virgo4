# app/controllers/concerns/config/articles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require_relative '_eds'

module Config

  ARTICLES_CONFIG = Config::Eds.instance

  # Config::Articles
  #
  class Articles

    include Config::Base

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    # @see Config::Eds#instance
    #
    def initialize
      super(ARTICLES_CONFIG)
    end

  end

  # Assign class lens key.
  Articles.key = ARTICLES_CONFIG.lens_key

  # Sanity check.
  Blacklight::Lens.validate_key(Articles)

end

__loading_end(__FILE__)

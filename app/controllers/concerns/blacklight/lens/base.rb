# app/controllers/concerns/blacklight/lens/base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Compare with:
# @see Blacklight::Base
#
module Blacklight::Lens::Base

  extend ActiveSupport::Concern

  include Blacklight::Base
  include Blacklight::Lens::Export
  include Blacklight::Lens::Facet
  include Blacklight::Lens::SearchContext

  included do |base|
    __included(base, 'Blacklight::Lens::Base')
  end

end

__loading_end(__FILE__)

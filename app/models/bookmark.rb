# app/models/bookmark.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# This extends the model defined in the Blacklight gem to include the added
# :search_lens column.
#
class Bookmark < ActiveRecord::Base

  include LensHelper

  # The search lens associated with this bookmark instance.
  #
  # @return [Symbol]
  #
  def lens
    search_lens.to_s.to_sym.presence || current_lens_key
  end

end

__loading_end(__FILE__)

# app/models/lens_document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Blacklight::Document for items not associated with a specific indexing
# service.
#
# @see Blacklight::Lens::Document
# @see Blacklight::Document
#
class LensDocument
  include Blacklight::Document
  include Blacklight::Document::Base
  include Blacklight::Lens::Document
end

__loading_end(__FILE__)

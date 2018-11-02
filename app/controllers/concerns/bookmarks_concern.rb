# app/controllers/concerns/bookmarks_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookmarksConcern
#
module BookmarksConcern

  extend ActiveSupport::Concern

  include Blacklight::Lens::Bookmarks
  include ExportConcern
  include MailConcern
  include SearchConcern

  included do |base|
    __included(base, 'BookmarksConcern')
  end

end

__loading_end(__FILE__)

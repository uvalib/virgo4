# app/helpers/about_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AboutHelper
#
# @see AboutController
# @see app/views/about
#
module AboutHelper

  require_files(__FILE__, 'about_helper/*.rb')

  def self.included(base)
    __included(base, '[AboutHelper]')
  end

  include AboutHelper::Internal
  include AboutHelper::List
  include AboutHelper::Solr
  include AboutHelper::Log

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the current user is authorized for internal information.
  #
  # TODO: There should be an "AuthorizationConcern" or something like it...
  #
  def authorized?
    @authorized ||= current_user.present? # TODO: Check for authorization
  end

end

__loading_end(__FILE__)

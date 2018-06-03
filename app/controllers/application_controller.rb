# app/controllers/application_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/_ext'

# Replaces the Blacklight class of the same name.
#
class ApplicationController < ActionController::Base

  include Blacklight::ControllerExt
  include SessionConcern

  # Needed for RubyMine to indicate overrides.
  include Devise::Controllers::Helpers unless ONLY_FOR_DOCUMENTATION

  protect_from_forgery with: :exception

  add_flash_types :error, :success

  layout 'application'

  # ===========================================================================
  # :section: Devise::Controllers::Helpers overrides
  # ===========================================================================

  protected

  # after_sign_in_path_for
  #
  # @return [String]
  #
  # This method overrides:
  # @see Devise::Controllers::Helpers#after_sign_in_path_for
  #
  def after_sign_in_path_for(*)
    session[:current_url].presence || root_path
  end

  # after_sign_in_path_for
  #
  # @return [String]
  #
  # This method overrides:
  # @see Devise::Controllers::Helpers#after_sign_out_path_for
  #
  def after_sign_out_path_for(*)
    '/account/signed_out'
  end

end

__loading_end(__FILE__)

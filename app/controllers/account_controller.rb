# app/controllers/account_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User account controller.
#
# TODO: Need to determine how this plays with Devise
#
class AccountController < ApplicationController

  include LensConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /account
  #
  def index
  end

  # == GET /account/signed_out
  #
  def signed_out
  end

end

__loading_end(__FILE__)

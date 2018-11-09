# app/controllers/concerns/rescue_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# RescueConcern
#
module RescueConcern

  extend ActiveSupport::Concern

  included do |base|

    __included(base, 'RescueConcern')

    # =========================================================================
    # :section: Controller exception handling
    # =========================================================================

    public

    rescue_from *[
      Errno::ECONNABORTED,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::EHOSTDOWN,
      Errno::EHOSTUNREACH,
      Errno::ENETDOWN,
      Errno::ENETRESET,
      Errno::ENETUNREACH,
      Faraday::ConnectionFailed,
      Faraday::TimeoutError,
    ], with: :handle_connect_error

    # The index action will more than likely throw this one.
    # Example: when the standard query parser is used, and a user submits a
    # "bad" query.
    rescue_from *[
      Blacklight::Exceptions::InvalidRequest
    ], with: :handle_request_error

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Redirect back.
  #
  # @param [Array] *args
  # - [String, Hash] msg
  # - [String]       fallback_path
  #
  def go_back(*args)
    opt = args.last.is_a?(Hash) ? args.pop.dup : {}
    msg = args.shift
    opt[:error] = msg if msg
    fallback_path = opt.delete(:fallback)
    fallback_path = opt.delete(:fallback_location) || fallback_path
    fallback_path = args.shift || fallback_path || root_path
    redirect_back opt.reverse_merge(fallback_location: fallback_path)
  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  protected

  # This method is executed when there is a problem communicating with an
  # external service.
  #
  # @param [Exception]           exception
  # @param [String, Symbol, nil] i18n
  #
  # == Implementation Notes
  # Because the lens home pages send a request in order to fill the facet
  # selections, if a request fails due to failure to connect to a service then
  # there are only two safe choices:
  #
  #   1. Redirect to the lens main page
  #   2. Redirect to the home page
  #
  # The problem with either is that the landing page has to be able to avoid
  # attempting to fill facet selections by making a request to the failing
  # service.  Otherwise the page won't display so the user will never see the
  # flash message about the service failure.
  #
  def handle_connect_error(exception, i18n = nil)
    i18n ||= 'blacklight.search.errors.connect.general'
    flash_notice = I18n.t(i18n, error: exception.class)
    handle_generic_error(exception, flash_notice, root_path)
  end

  # This method is executed when Blacklight::Exceptions::InvalidRequest has
  # been raised.
  #
  # @param [Exception]           exception
  # @param [String, Symbol, nil] i18n
  #
  # This method overrides:
  # @see Blacklight::Base#handle_request_error
  #
  def handle_request_error(exception, i18n = nil)
    # If there are errors coming from the index page, we want to trap those
    # sensibly.
    flash_notice = i18n && I18n.t(i18n, default: '').presence
    flash_notice ||= I18n.t('blacklight.search.errors.request_error')
    handle_generic_error(exception, flash_notice, search_action_path)
  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  private

  # handle_generic_error
  #
  # @param [Exception] exception
  # @param [String]    flash_notice
  # @param [String]    redirect_path
  #
  def handle_generic_error(exception, flash_notice, redirect_path)
    if flash[:notice] == flash_notice
      Log.error(__method__, 'request is looping', flash_notice)
      raise exception
    elsif request.xhr?
      # TODO: not clear if this is actually the desired behavior in this case
      Log.error(exception)
      flash[:notice] = nil
      flash.now[:notice] = flash_notice
    else
      Log.error(exception)
      redirect_to redirect_path, notice: flash_notice
    end
  end

end

__loading_end(__FILE__)

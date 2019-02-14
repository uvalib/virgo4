# app/controllers/concerns/eds_concern.rb
#
# encoding:              utf-8
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Common concerns of controllers that work with articles (EdsDocument).
#
module EdsConcern

  extend ActiveSupport::Concern

  include Blacklight::Lens::Base
  include ExportConcern
  include MailConcern
  include SearchConcern

  included do |base|

    __included(base, 'EdsConcern')

    include RescueConcern

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :default_catalog_controller if respond_to?(:helper_method)

    # =========================================================================
    # :section: Controller exception handling
    # =========================================================================

    # Connection errors cause a return to the home page.
    rescue_from *[
      EBSCO::EDS::ConnectionFailed,
      EBSCO::EDS::ServiceUnavailable,
    ], with: :handle_connect_error

    # Handle EBSCO EDS communication failures.
    rescue_from EBSCO::EDS::Error, with: :handle_ebsco_eds_error

  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  protected

  # Handle EBSCO EDS communication failures (EBSCO::EDS::Error).
  #
  # @param [Exception] exception
  #
  # @see http://edswiki.ebscohost.com/API_Reference_Guide:_Error_Codes
  # @see http://edswiki.ebscohost.com/API_Reference_Guide:_Authentication_Error_Codes
  # @see https://help.ebsco.com/interfaces/EBSCOhost/EBSCOhost_FAQs/error_message_when_log_in_to_EBSCOhost
  #
  def handle_ebsco_eds_error(exception)

    # Extract EBSCO fault information.
    fault = (exception.fault    if exception.respond_to?(:fault))
    fault = (fault[:error_body] if fault.is_a?(Hash)) || {}

    # Get error values.
    details = fault['AdditionalDetail'] || fault['DetailedErrorDescription']
    code    = fault['ErrorCode']        || fault['ErrorNumber']
    message = fault['Reason']           || fault['ErrorDescription']
    message ||= exception&.message&.demodulize
    message ||= I18n.t('blacklight.search.errors.unknown')
    if details.present?
      message = message.chomp('.') << +' (' << details.chomp('.') << ')'
    elsif code.present?
      message = message.chomp('.') << " [#{code}]"
    end
    message = I18n.t('blacklight.search.errors.ebsco_eds', error: message)

    # Act based on the type of error.
    case code.to_i

      when 104, 108, 113, 127, 128, 133..135, 139..141, 144, 1100..1103
        # === Authentication error
        # Nothing in /articles will work in this case so redirecting to
        # articles_home_path would just result in a "redirect loop".
        Log.error(exception)
        flash[:notice] = I18n.t('blacklight.search.errors.authorization.eds')
        redirect_to root_path

      when 106
        # === "Unknown error encountered"
        Log.warn(exception)
        flash[:notice] =
          I18n.t('blacklight.search.errors.receive.eds', error: message)
        redirect_to root_path

      when 107
        # === "Authentication Token Missing"
        Log.error(exception)
        flash[:notice] =
          I18n.t('blacklight.search.errors.authorization.eds_blocked')
        redirect_to root_path

      when 109
        # === "Session Token Invalid"
        # This condition triggers automatic acquisition of a new session token
        # and it occurs regularly during the normal course of a session so
        # there's no need to alert or redirect.
        Log.debug(exception, '[ignore]')

      when 114, 137, 148, 150..152
        # === E.g.: "Retrieval Request AN must contain a valid value."
        # An error when already on an articles index page or show page for an
        # action that wasn't expected to go to a different page.
        Log.warn(exception)
        flash.now[:notice] = message

      else
        Log.error(exception)
        flash[:notice] = message
        redirect_to articles_home_path
    end

  end

end

__loading_end(__FILE__)

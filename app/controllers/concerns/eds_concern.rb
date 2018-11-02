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
    end
    message = I18n.t('blacklight.search.errors.ebsco_eds', error: message)

    # Act based on the type of error.
    case code.to_i
      when 101, 102, 103, 104, 105, 113, 130, 131, 132, 133, 134, 135,
        1100, 1103
        # TODO: Determine whether this is correct for all of these error codes
        flash[:notice] =
          I18n.t('blacklight.search.errors.authorization.eds')
        Log.debug(exception, '[ignore]')
        redirect_to articles_home_path
      when 106
        # EBSCO::EDS::BadRequest
        # "Unknown error encountered"
        flash[:notice] =
          I18n.t('blacklight.search.errors.receive.eds', error: message)
        Log.warn(exception)
        redirect_to articles_home_path
      when 107
        flash[:notice] =
          I18n.t('blacklight.search.errors.authorization.eds_blocked')
        Log.error(exception)
        redirect_to articles_home_path
      when 109
        # EBSCO::EDS::BadRequest
        # "Session Token Invalid"
        Log.debug(exception, '[ignore]')
      when 114
        # EBSCO::EDS::BadRequest
        # "Retrieval Request AN must contain a valid value."
        flash.now[:notice] = message
        Log.warn(exception)
      when 1102
        flash[:notice] = message
        Log.debug(exception, '[ignore]')
        redirect_to articles_home_path
      else
        flash[:notice] = message
        Log.error(exception)
        redirect_to articles_home_path
    end
  end

end

__loading_end(__FILE__)

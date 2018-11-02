# app/helpers/mail_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The "non-routable" methods from Blacklight::Catalog which are also needed by
# non-catalog controllers like BookmarksController.
#
module MailHelper

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Catalog unless ONLY_FOR_DOCUMENTATION

  def self.included(base)
    __included(base, '[MailHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides - E-mail
  # ===========================================================================

  public

  # Email action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  #
  # @param [Array<Blacklight::Document>] documents
  #
  # This method overrides:
  # @see Blacklight::Catalog#email_action
  #
  def email_action(documents)
    details = { to: params[:to], message: params[:message] }
    url_opt = url_options
    mail = RecordMailer.email_record(documents, details, url_opt)
    mail.respond_to?(:deliver_now) ? mail.deliver_now : mail.deliver
  end

  # validate_email_params
  #
  # @return [TrueClass, FalseClass]
  #
  # This method overrides:
  # @see Blacklight::Catalog#validate_email_params
  #
  def validate_email_params
    flash.clear
    error = []
    addr = params[:to]
    if addr.blank?
      error << I18n.t('blacklight.email.errors.to.blank')
    elsif !addr.match(Blacklight::Engine.config.email_regexp)
      error << I18n.t('blacklight.email.errors.to.invalid', to: addr)
    end
    flash[:error] = error.join("<br/>\n").html_safe if error.present?
    flash[:error].blank?
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides - SMS text
  # ===========================================================================

  public

  # A table of wireless carriers and hostnames.
  #
  # @return [Hash{String=>String}]
  #
  # This method overrides:
  # @see Blacklight::Catalog#sms_mappings
  #
  # TODO: Replace the embedded table with data from a YAML file.
  #
  def sms_mappings
    super
  end

  # SMS action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  #
  # @param [Array<Blacklight::Document>] documents
  #
  # This method overrides:
  # @see Blacklight::Catalog#sms_action
  #
  def sms_action(documents)
    ph_number = params[:to].to_s.gsub(/[^\d]/, '')
    carrier   = params[:carrier]
    details   = { to: "#{ph_number}@#{carrier}" }
    url_opt   = url_options
    mail = RecordMailer.sms_record(documents, details, url_opt)
    mail.respond_to?(:deliver_now) ? mail.deliver_now : mail.deliver
  end

  # validate_sms_params
  #
  # @return [TrueClass, FalseClass]
  #
  # This method overrides:
  # @see Blacklight::Catalog#validate_sms_params
  #
  def validate_sms_params
    flash.clear
    error = []
    ph_number = params[:to]
    if ph_number.blank?
      error << I18n.t('blacklight.sms.errors.to.blank')
    elsif ph_number.gsub(/[^\d]/, '').length != 10
      error << I18n.t('blacklight.sms.errors.to.invalid', to: ph_number)
    end
    carrier = params[:carrier]
    if carrier.blank?
      error << I18n.t('blacklight.sms.errors.carrier.blank')
    elsif !sms_mappings.values.include?(carrier)
      error << I18n.t('blacklight.sms.errors.carrier.invalid')
    end
    flash[:error] = error.join("<br/>\n").html_safe if error.present?
    flash[:error].blank?
  end

end

__loading_end(__FILE__)

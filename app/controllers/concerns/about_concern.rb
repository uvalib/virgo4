# app/controllers/concerns/about_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support log file viewing.
#
module AboutConcern

  extend ActiveSupport::Concern

  include AboutHelper

  included do |base|
    __included(base, 'AboutConcern')
  end

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  protected

  # determine_layout
  #
  # @return [String, FalseClass]
  #
  # This method overrides
  # @see Blacklight::Controller#determine_layout
  #
  def determine_layout
    !request.xhr? && super
  end

  # ===========================================================================
  # :section: List
  # ===========================================================================

  public

  # get_topic
  #
  # @param [Hash] src
  #
  # @return [Symbol, nil]
  #
  def get_topic(src)
    src[:topic].presence&.singularize&.downcase&.to_sym
  end

  # get_topic_list
  #
  # @param [Symbol] topic
  #
  # @return [Array<String>]
  #
  def get_topic_list(topic)
    case topic
      when :library  then IlsService.new.get_library_list
      when :location then IlsService.new.get_location_list
      else                [%Q(#{__method__}: unknown: "#{topic}")]
    end
  end

  # ===========================================================================
  # :section: Log
  # ===========================================================================

  public

  # Return an HTTP error response.
  #
  # @param [Symbol, Array<String>] arg
  # @param [Hash, nil]             opt
  #
  # @return [void]
  #
  def respond_with(arg, opt = nil)
    opt ||= {}
    if arg.is_a?(Symbol)
      opt.reverse_merge!(layout: false, status: arg)
      msg = error_message(arg)
      respond_to do |format|
        format.html { opt.merge!(html: msg) }
        format.json { opt.merge!(json: msg.to_json) }
        format.xml  { opt.merge!(xml:  { error: msg }.to_xml) }
      end
    else
      opt = opt.dup
      @lines = Array.wrap(arg)
      respond_to do |format|
        format.html { opt.merge!(layout: determine_layout) }
        format.json { opt.merge!(json:   decolorize_lines(@lines).to_json) }
        format.xml  { opt.merge!(xml:    decolorize_lines(@lines).to_xml) }
      end
    end
    render opt
  end

  # Translate a symbolic error code into an error message.
  #
  # @param [Symbol] code
  #
  # @return [String]
  #
  def error_message(code)
    code    = Rack::Utils::status_code(code)
    message = Rack::Utils::HTTP_STATUS_CODES[code]
    "#{code} #{message}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Called before actions that require authorization.
  #
  # @return [TrueClass]                           The session is authorized.
  # @return [FalseClass]                          The session is not authorized
  #
  # @raise [Blacklight::Exceptions::AccessDenied] No user.
  # @raise [Net::HTTPUnauthorized]                Unauthorized user.
  #
  # @see self#verify_user
  #
  def verify_session
    if request.xhr? && !authorized?
      respond_with(:unauthorized)
      false
    else
      verify_user
    end
  end

  # Called before actions that require authorization.
  #
  # @return [TrueClass]                           The user is authorized.
  # @return [FalseClass]                          The session is not authorized
  #
  # @raise [Blacklight::Exceptions::AccessDenied] The user is not logged in.
  # @raise [Net::HTTPUnauthorized]                The user is unauthorized.
  #
  def verify_user
    if authorized?
      true
    elsif request.xhr?
      false
    elsif current_user
      flash[:notice] = I18n.t('blacklight.about.error.unauthorized')
      raise Net::HTTPUnauthorized
    else
      flash[:notice] = I18n.t('blacklight.about.error.no_user')
      raise Blacklight::Exceptions::AccessDenied
    end
  end

end

__loading_end(__FILE__)

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
      when :library  then %w(TODO Libraries from\ Firehose) # TODO: Firehose library list
      when :location then %w(TODO Locations from\ Firehose) # TODO: Firehose location list
      else                [%Q(#{__method__}: unknown: "#{topic}")]
    end
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

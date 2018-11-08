# app/controllers/concerns/search_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This module encapsulates the creation of a SearchService derivative that
# includes contextual information (in particular, the nature of the user who is
# preforming the search).
#
module SearchConcern

  extend ActiveSupport::Concern

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Catalog unless ONLY_FOR_DOCUMENTATION

  include LensConcern

  included do |base|
    __included(base, 'SearchConcern')
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  public

  # A memoized instance of the parameter state.
  #
  # This includes a pointer to the session, current user, and other information
  # that may be needed by the various search services.
  #
  # @param [Array] args
  #
  # @overload search_service
  #
  # @overload search_service(usr_params)
  #
  # @overload search_service(usr_params, context)
  #
  # @overload search_service(usr_params, req)
  #
  # @overload search_service(usr_params, req, context)
  #
  # @overload search_service(usr_params, user)
  #
  # @overload search_service(usr_params, user, context)
  #
  # @return [Blacklight::Lens::SearchService]
  #
  # This method overrides:
  # @see Blacklight::Catalog#search_state
  #
  def search_service(*args)
    # The first argument are the search terms ("user parameters").  Additional
    # ("service parameters") may be the last argument.
    usr_params =
      case args.first
        when Hash                         then args.shift.dup
        when ActionController::Parameters then args.shift.to_unsafe_h
        else                                   {}
      end
    context = args.last.is_a?(Hash) ? args.pop.dup : {}

    # Handle any any other arguments.
    args.each do |arg|
      case arg
        when User                         then context[:user]           = arg
        when Hash                         then context[:service_params] = arg
        when ActionDispatch::Request      then context[:request]        = arg
        when ActionController::Parameters then usr_params.reverse_merge!(arg)
      end
    end
    context[:user] ||= current_user # TODO: keep?
    usr_params = search_state.to_h unless usr_params.present?
    srv_params = context[:service_params] ||= {}

    # Look for context values needed by Blacklight::Eds::SearchService.
    Blacklight::Eds::EDS_PARAMS.each do |k|
      srv_params[k] = context.delete(k) || srv_params[k]
    end

    # Values used by Blacklight::Eds::SearchService (@see #EDS_SESSION_PARAMS).
    srv_params[:authenticated] ||= !current_or_guest_user.guest
    srv_params[:session]       ||= session

    # Values used by EBSCO EDS API (@see #EDS_API_PARAMS).
    srv_params[:guest]         ||= session[:guest]
    srv_params[:session_token] ||= session[:eds_session_token]

    # Create the search service with search parameters and context info.
    controller.search_service_class.new(blacklight_config, usr_params, context)
  end

end

__loading_end(__FILE__)

# app/controllers/concerns/session_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# SessionConcern
#
module SessionConcern

  extend ActiveSupport::Concern

  include BlacklightConfigurationHelper

  included do |base|

    __included(base, 'SessionConcern')

    # =========================================================================
    # :section: Controller filter actions
    # =========================================================================

    # rubocop:disable Metrics/LineLength

    # Actions that might result in a redirect or might modify the session.

    before_action :set_current_url
=begin # NOTE: Virgo 3 filters not yet investigated
    before_action :recaptcha_check,           only: [:send_email_record]
    before_action :adjust_old_style_params,   only: [:page_turner]
    before_action :update_show_page_context,  only: [:update]
    before_action :adjust_for_search_context, only: [:show]
    before_action :adjust_for_full_view,      only: [:show]
    before_action :adjust_for_classic,        only: [:index, :show]
    before_action :adjust_for_spec_coll,      only: [:index]
    before_action :validate_advanced,         only: [:index]
=end
    before_action :set_origin,                only: [:index]
    before_action :resolve_sort,              only: [:index]
    before_action :cleanup_parameters
    before_action :conditional_redirect

    # Actions involved in data acquisition (and might result in an exception).

=begin # NOTE: Virgo 3 filters not yet investigated
    before_action :get_document_list,         only: [:index]
    before_action :get_advanced_facets,       only: [:advanced]
    before_action :add_lean_query_type,       only: [:brief_availability, :image, :image_load]
    before_action :get_solr_document,         only: [:show, :availability, :brief_availability, :fedora_metadata, :firehose, :hierarchy_children, :iiif, :image, :image_load, :page_turner, :tei]
    before_action :set_documents,             only: [:email, :sms, :citation, :endnote, :ris]
    before_action :set_articles,              only: [:email, :sms, :citation, :endnote, :ris]
=end

    # Other actions before the page is rendered.

=begin # NOTE: Virgo 3 filters not yet investigated
    before_action :suppress_shelf_browse,     only: [:index, :show, :availability, :brief_availability]
    before_action :notices_update,            only: [:index, :show]
=end

    # Actions after the page is rendered.

=begin # NOTE: Virgo 3 filters not yet investigated
    after_action  :set_cors_headers
=end

    # rubocop:enable Metrics/LineLength

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Accumulator for the URL parameters to be used for redirection after
  # "before" filters have been run.
  #
  # @param [String, Hash] url
  #
  # @return [true]                    Default setting which will cause the
  #                                     final state of `params` to be used by
  #                                     self#conditional_redirect.
  # @return [false]                   Setting by an intermediate filter
  # @return [String]
  # @return [Hash]
  #
  # @see self#conditional_redirect
  #
  def will_redirect(url = nil)
    if url.present?
      session[:redirect] = url
    else
      session[:redirect] ||= true
    end
  end

  # ===========================================================================
  # :section: Controller filter actions
  # ===========================================================================

  public

  # Set current page used by Devise as the redirect target after sign-in.
  #
  # @return [void]
  #
  def set_current_url
    return if params[:controller].to_s.start_with?('devise')
    session[:current_url] = request.original_url
  end

  # Visiting the index page of a controller sets the session origin.
  #
  # This allows pages to behave differently depending on whether they are
  # reached from a search, or from somewhere else like Bookmarks.
  #
  # @return [void]
  #
  def set_origin
    return unless params[:action] == 'index'
    origin = (params[:controller].presence unless request.path == root_path)
    session[:origin] = origin || :root
  end

  # Change or eliminate :sort based on the request URL.  Additionally, remove
  # :sort, :view and/or :per_page for main page and lens home pages.
  #
  # @return [void]
  #
  def resolve_sort
    base_params = params.except(:controller, :action)
    return unless base_params.present? && Blacklight::Lens.key_for(self, false)
    changed = false
    sort = base_params.delete(:sort)
    view = base_params.delete(:view)
    prpg = base_params.delete(:per_page)
    if base_params.blank?
      # For the main page and lens home pages, eliminate parameters that would
      # needlessly result in a cache miss.
      changed = params.delete(:sort)     if sort.present?
      changed = params.delete(:view)     if view.present?
      changed = params.delete(:per_page) if prpg.present?
    else
      # For search results, change the sort if required.
      relevance = relevance_sort_key
      received  = date_received_sort_key
      published = 'newest'
      new_sort =
        if params[:format] == 'rss'
          # Special case for RSS; otherwise sort by date_received.
          received unless sort == published
        elsif has_query?
          # If there is a query, sort by relevance unless a sort was specified.
          relevance unless sort.present?
        elsif sort == relevance
          # If there is no query, sorting by relevance doesn't make sense;
          # default to sorting by date received except for digital collections.
          params[:f]&.include?(:digital_collection_f) ? published : received
        end
      changed = (sort != new_sort) if new_sort.present?
      params[:sort] = new_sort if changed
    end
    will_redirect if changed
  end

  # Clean up URL parameters and redirect.
  #
  # This eliminates "noise" parameters injected by the advanced search forms
  # and other situations where empty or unneeded parameters accumulate.
  #
  def cleanup_parameters

    changed = false
    original_size = params.to_unsafe_h.size

    # Eliminate "noise" parameters (usually generated from the advanced search
    # form), including 'op="AND"' since this is always the default logical
    # operation.
    params.delete_if { |k, v| k.blank? || v.blank? }
    %w(utf8).each { |k| params.delete(k) }
    params.delete(:op) if params[:op] == 'AND'
    params.delete(:commit)
    debugging = params.delete(:virgo_debug)

    # Update session if indicated.
    case debugging.to_s.downcase
      when 'true'  then session[:virgo_debug] = true
      when 'false' then session.delete(:virgo_debug)
    end

    # If parameters were removed, redirect to the corrected URL.
    changed ||= (params.to_unsafe_h.size != original_size)
    will_redirect if changed

  end

  # To be run after all before_actions that modify params and require a
  # redirect in order to "correct" the Virgo URL.
  #
  # @return [void]
  #
  # @see self#will_redirect
  #
  def conditional_redirect
    return unless request.get?
    path = session.delete(:redirect)
    path = params     if path.is_a?(TrueClass)
    redirect_to(path) if path.present?
  end

end

__loading_end(__FILE__)

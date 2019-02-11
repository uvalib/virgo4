# app/helpers/blacklight_url_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::UrlHelperBehavior
#
module BlacklightUrlHelper

  include Blacklight::UrlHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[BlacklightUrlHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::UrlHelperBehavior overrides
  # ===========================================================================

  public

  # url_for_document
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            opts
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see Blacklight::Lens::SearchState#url_for_document
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#url_for_document
  #
  def url_for_document(doc, opts = nil)
    search_state.url_for_document(doc, opts)
  end

  # Uses the catalog_path route to create a link to the show page for an item.
  #
  # catalog_path accepts a hash. The Solr query params are stored in the
  # session, so we only need the +counter+ param here. We also need to know if
  # we are viewing to document as part of search results.
  #
  # @param [Blacklight::Document] doc
  # @param [Symbol, Hash]         label_or_opts
  # @param [Hash]                 opts
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_document
  #
  def link_to_document(doc, label_or_opts = nil, opts = nil)
    if label_or_opts.is_a?(Hash)
      opts = label_or_opts
      label_or_opts = nil
    else
      opts ||= { counter: nil }
    end
    label =
      if label_or_opts.is_a?(Proc) || label_or_opts.is_a?(Symbol)
        Deprecation.warn(self,
          "passing a #{label_or_opts.class} (#{label_or_opts.inspect}) " \
          "to #{__method__} is deprecated and will be removed in Blacklight 8"
        )
        Deprecation.silence(Blacklight::IndexPresenter) do
          index_presenter(doc).label(label_or_opts, opts)
        end
      end
    label ||= label_or_opts
    label ||= index_presenter(doc).label(document_show_link_field(doc), opts)
    opts = document_link_params(doc, opts)
    lens = lens_key_for(opts.delete(:lens) || doc)
    path = url_for_document(doc, lens: lens)
    link_to(label, path, opts)
  end

  # Link to the previous document in the current search context.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_previous_document
  #
  def link_to_previous_document(doc, options = nil)
    label = t('views.pagination.previous').html_safe
    opt   = { class: 'previous' }
    opt.merge!(options) if options.is_a?(Hash)
    if (url = url_for_document(doc))
      count = search_session['counter'].to_i - 1
      opt.merge!(session_tracking_params(doc, count))
      opt[:rel] = 'prev'
      link_to(label, url, opt)
    else
      opt[:class] += ' disabled'
      opt[:title] = t('blacklight.search.pagination.at_beginning')
      content_tag(:span, label, opt)
    end
  end

  # Link to the next document in the current search context.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_to_next_document
  #
  def link_to_next_document(doc, options = nil)
    label = t('views.pagination.next').html_safe
    opt   = { class: 'next' }
    opt.merge!(options) if options.is_a?(Hash)
    if (url = url_for_document(doc))
      count = search_session['counter'].to_i + 1
      opt.merge!(session_tracking_params(doc, count))
      opt[:rel] = 'next'
      link_to(label, url, opt)
    else
      opt[:class] += ' disabled'
      opt[:title] = t('blacklight.search.pagination.at_end')
      content_tag(:span, label, opt)
    end
  end

  # controller_tracking_method
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#controller_tracking_method
  #
  def controller_tracking_method
    "track_#{current_lens.key}_path"
  end

  # Get the path to the search action with any parameters (e.g. view type)
  # that should be persisted across search sessions.
  #
  # @param [String] _query_params     Unused.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#start_over_path
  #
  # == Implementation Notes
  # Unlike the Blacklight method, this intentionally removes the :view
  # parameter to simplify the path.  Since :preferred_view will already be in
  # the session there's no need to communicate this setting through the
  # parameters.
  #
  def start_over_path(_query_params = nil)
    search_action_path(view: nil)
  end

  # Create a link back to the index screen, keeping the user's facet, query and
  # paging choices intact by using session.
  #
  # If the origin was the Bookmarks page, the link will return there instead.
  #
  # @param [Hash] opts
  #
  # @option opts [String] :label
  # @option opts [Symbol] :origin
  # @option opts [String] :anchor
  # @option opts [Object] :route_set
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @example
  #   link_back_to_catalog(label: 'Back to Search')
  #   link_back_to_catalog(label: 'Back to Search', route_set: my_engine)
  #
  # This method overrides:
  # @see Blacklight::UrlHelperBehavior#link_back_to_catalog
  #
  def link_back_to_catalog(opts = nil)
    opts = opts ? opts.dup : {}
    label  = opts.delete(:label)
    scope  = opts.delete(:route_set) || self
    origin = opts.delete(:origin)
    anchor = opts.delete(:anchor)
    from_bookmarks = (origin == :bookmarks)
    url_opt = {}
    url_opt = { anchor: anchor } if anchor.present?
    link_url =
      if from_bookmarks
        bookmarks_path(url_opt)
      else
        query_params = current_search_session&.query_params || {}
        query_params = search_state.reset(query_params).to_hash
        if (counter = search_session['counter'])
          spp      = search_session['per_page'].to_i
          default  = default_per_page.to_i
          per_page = [spp, default, 1].max
          query_params[:per_page] = per_page unless spp == default
          query_params[:page]     = ((counter.to_i - 1) / per_page) + 1
        end
        if query_params.present?
          url_opt.merge!(query_params)
          scope.url_for(url_opt)
        else
          url_opt.merge!(only_path: true)
          search_action_path(url_opt)
        end
      end
    label ||= t('blacklight.back_to_bookmarks') if from_bookmarks
    label ||= t('blacklight.back_to_search')
    link_to(label, link_url, opts)
  end

  # Search History and Saved Searches display
  def link_to_previous_search(params)
    link_to(render_search_to_s(params), search_action_path(params))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # To be used in place of #opensearch_catalog_url.
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # Because this is being called from the layout and not from an action
  # template, #url_for is actually ActionView::RoutingUrlFor#url_for rather
  # than ActionDispatch::Routing::UrlFor#url_for.
  #
  # This variant was causing a crash when trying to sign in because the current
  # controller ("/devise/sessions") was resulting in the requested path for
  # `{ controller: 'catalog', action: 'opensearch' }` to be interpreted as
  # `{ controller: '/devise/catalog', action: 'opensearch' }`.
  #
  # Prefixing the controller name with '/' avoids that interpretation.
  #
  def opensearch_url(options = nil)
    opt = search_state.to_h.merge(only_path: false)
    opt.merge!(options) if options.present?
    opt.merge!(controller: "/#{current_lens_key}", action: 'opensearch')
    url_for(opt)
  end

end

__loading_end(__FILE__)

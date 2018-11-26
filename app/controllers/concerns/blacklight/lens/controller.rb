# app/controllers/concerns/blacklight/lens/controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Filters added to this controller apply to all controllers in the
# hosting application as this module is mixed-in to the application controller
# in the hosting app on installation.
#
# Compare with:
# @see Blacklight::Controller
#
module Blacklight::Lens::Controller

  extend ActiveSupport::Concern

  include Blacklight::Controller
  include BlacklightAdvancedSearch::Controller
  include Blacklight::Lens::Base

  included do |base|

    __included(base, 'Blacklight::Lens::Controller')

    if respond_to?(:layout)
      layout(respond_to?(:determine_layout) ? :determine_layout : 'blacklight')
    end

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper Blacklight::Lens::SearchFields if respond_to?(:helper)

    # =========================================================================
    # :section: Class attributes
    # =========================================================================

    self.search_state_class   = Blacklight::Lens::SearchState
    self.search_service_class = Blacklight::Lens::SearchService

  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  module ClassMethods

    # Define view_path prefixes so that view templates can be defined as needed
    # for a lens with a fall-back to 'app/views/catalog'.
    #
    # @return [Array<String>]
    #
    # This method overrides:
    # @see ActionView::ViewPaths::ClassMethods#_prefixes
    #
    def _prefixes # :nodoc:
      return local_prefixes if superclass.abstract?
      @_prefixes ||= (
      local_prefixes +
        [Blacklight::Lens.default_lens_key.to_s] +
        superclass._prefixes
      ).uniq
    end

    # =========================================================================
    # :section: Blacklight 7 pre-release
    #
    # Deprecated usage of adding tools outside of the context of configuration
    # is actively avoided (rather than just warning about deprecation).
    # =========================================================================

    %i(
      add_results_document_tool
      add_results_collection_tool
      add_nav_action
      add_show_tools_partial
    ).each do |method|
      class_eval <<-EOS
        def #{method}(*args)
          Blacklight.logger.warn do
            "SKIPPING DEPRECATED #{method}(\#{args.inspect})"
          end
        end
      EOS
    end

  end

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  public

  # Undo the delegation of :blacklight_config to :default_catalog_controller
  # that is performed by Blacklight::Controller.
  #
  # This uses the same signature as the one generated by #delegate.
  #
  def blacklight_config(*args, &block)
    blacklight_config_for(args.first)
  end

  # ===========================================================================
  # :section: Blacklight::Controller overrides
  # ===========================================================================

  private

  # A memoized instance of the parameter state.
  #
  # @return [Blacklight::Solr::SearchState]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_state
  #
  def search_state
    @search_state ||= search_state_class.new(params, blacklight_config, self)
  end

  # Returns the search URL for the current lens.
  #
  # @param [Hash] options
  #
  # @option options [Symbol]  :lens       Specify the controlling lens; default
  #                                         is `current_lens_key`.
  #
  # @option options [Boolean] :canonical  If *true* return the path for the
  #                                         canonical controller related to
  #                                         the current controller or to :lens.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_action_url
  #
  # == Implementation Notes
  # The controller must be given as an absolute path so that #url_for does not
  # replace :controller with the Devise controller within 'account' pages.
  #
  # TODO: does not always override Blacklight::Controller#search_action_url
  # @see AdvancedSearchConcern#search_action_url
  # @see Blacklight::Lens::Catalog#search_action_url
  # @see Blacklight::Lens::Bookmarks#search_action_url
  #
  def search_action_url(options = nil)
    opt = (options || {}).merge(action: 'index')
    lens = opt.delete(:lens) || current_lens_key
    canonical = opt.delete(:canonical)
    canonical &&= Blacklight::Lens.canonical_for(lens)
    opt[:controller] = "/#{canonical || lens}"
    url_for(opt)
  end

  # search_facet_url
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # @deprecated Use self#search_facet_path
  #
  # This method overrides:
  # @see Blacklight::Controller#search_facet_url
  #
  def search_facet_url(options = nil)
    opt = { only_path: false }
    opt.merge!(options) if options.present?
    search_facet_path(opt)
  end
  deprecate(search_facet_url: 'Use search_facet_path instead.')

  # This overrides the Blacklight method only to silence deprecation warnings.
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Controller#search_facet_path
  #
  def search_facet_path(options = nil)
    opt = search_state.to_h.merge(only_path: true)
    opt.merge!(options) if options.present?
    opt.merge!(controller: current_lens_key, action: 'facet')
    opt.except!(:page)
    url_for(opt)
  end

  # Indicate whether to display bookmarks controls.
  #
  # This method overrides:
  # @see Blacklight::Controller#render_bookmarks_control?
  #
  def render_bookmarks_control?
    !disabled?(:bookmarks_control) &&
      has_user_authentication_provider? && current_or_guest_user.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Defined for flexibility in defining methods that use #search_state_class
  # and #search_service_class.
  #
  # @return [Blacklight::Controller]
  #
  def controller
    self
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether to display the saved searches link.
  #
  def render_saved_searches?
    !disabled?(:saved_searches) &&
      has_user_authentication_provider? && current_user.present?
  end

  # Indicate whether to display the search history link.
  #
  def render_search_history?
    !disabled?(:search_history) &&
      has_user_authentication_provider? && current_or_guest_user.present?
  end

  # Indicate whether the bookmark tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def render_bookmark_action?(_config, _opt)
    !disabled?(:bookmark)
  end

  # Indicate whether the email tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def render_email_action?(_config, _opt)
    !disabled?(:email)
  end

  # Indicate whether the SMS text tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  # This method overrides:
  # @see Blacklight::Catalog#render_sms_action?
  #
  def render_sms_action?(_config, _opt)
    !disabled?(:sms) && super
  end

  # Indicate whether the bibliographic citation tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def render_citation_action?(_config, _opt)
    !disabled?(:citation)
  end

  # Indicate whether the librarian view tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             opt
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_librarian_view_control?
  #
  def render_librarian_view_control?(_config, opt)
    !disabled?(:librarian_view) &&
      if_any?(opt) { |doc| doc.has_marc? }
  end

  # Indicate whether the RefWorks export tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             opt
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_refworks_action?
  #
  def render_refworks_action?(_config, opt)
    !disabled?(:refworks) &&
      if_any?(opt) { |doc| doc.exports_as?(export_format[:refworks]) }
  end

  # Indicate whether the RefWorks export tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             opt
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_endnote_action?
  #
  def render_endnote_action?(_config, opt)
    !disabled?(:endnote) &&
      if_any?(opt) { |doc| doc.exports_as?(export_format[:endnote]) }
  end

  # Indicate whether the Zotero RIS export tool item should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             opt
  #
  def render_zotero_action?(_config, opt)
    !disabled?(:zotero) &&
      if_any?(opt) { |doc| doc.exports_as?(export_format[:zotero]) }
  end

  # Indicate whether the sort control should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def render_sort_widget?(_config, _opt)
    !disabled?(:sort)
  end

  # Indicate whether the page size control should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def render_per_page_widget?(_config, _opt)
    !disabled?(:per_page)
  end

  # Indicate whether the view group control should be displayed.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def render_view_type_group?(_config, _opt)
    !disabled?(:view_type_group)
  end

  # Indicate whether JSON should be rendered.
  #
  # @param [Blacklight::Configuration::Field] _config Unused.
  # @param [Hash]                             _opt    Unused.
  #
  def json_request?(_config, _opt)
    request.format.json?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Indicate whether an action is disabled.
  #
  # @param [Symbol] action
  #
  def disabled?(action)
    disabled_actions ||= {}
    disabled_actions[action].present?
  end

  # Disable/enable display of a control or feature.
  #
  # @param [Symbol]  action
  # @param [Boolean] disabling        If *false*, enable the action.
  #
  def disable(action, disabling = true)
    if (action == :all) && !disabling
      disabled_actions = {}
    else
      disabled_actions ||= {}
      disabled_actions[action] = disabling
    end
  end

  # For the given documents (either one or more documents directly or one or
  # more documents in a hash at key :document), indicate whether any meet the
  # criteria supplied via the block.
  #
  # @param [Hash, Blacklight::Document, Array<Blacklight::Document] docs
  #
  # @options docs [Blacklight::Document, Array<Blacklight::Document>] :document
  #
  # @yield [Blacklight::Document]
  #
  def if_any?(docs)
    docs = docs[:document] if docs.is_a?(Hash)
    docs ||= @document || @documents || @document_list
    docs = Array.wrap(docs)
    docs.any? { |doc| yield(doc) if doc.is_a?(Blacklight::Document) }
  end

end

__loading_end(__FILE__)

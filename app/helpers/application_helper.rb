# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common helper methods.
#
module ApplicationHelper

  include UVA::Constants
  include UVA::Networks

  include HtmlHelper

  def self.included(base)
    __included(base, '[ApplicationHelper]')
  end

  # Displayed only if a method is set up to avoid returning *nil*.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  # @see self#return_empty
  #
  NO_LINK_DISPLAY = I18n.t('blacklight.no_link').html_safe.freeze

  # Indicate whether a method should return *nil* if there was no data.
  # If *false* then self#NO_LINK_DISPLAY is returned.
  #
  # @type [Hash{Symbol=>Boolean}]
  #
  # @see self#return_empty
  #
  RETURN_NIL = {
    doi_link: false,
    url_link: true,
  }

  # URL sign-on path.
  #
  # @type [String]
  #
  SIGN_ON_PATH = '/account/login'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a path to sign on and redirect to the given path.
  #
  # @param [String, nil] return_path  URL to redirect to after sign on.
  #
  # @return [String]
  #
  def signon_redirect(return_path = nil)
    return_path = request&.path || root_url if return_path.blank?
    full_path, anchor = return_path.split('#')
    full_path << (full_path.include?('?') ? '&' : '?')
    full_path << 'refresh=true' # TODO: Implement to avoid using the cached version of the destination page.
    full_path << ('#' + anchor) if anchor.present?
    full_path = CGI.escape(full_path)
    "#{SIGN_ON_PATH}?redirect=#{full_path}"
  end

  # Indicate whether the ultimate target format is HTML.
  #
  # @param [Hash, nil] opt
  #
  def rendering_html?(opt)
    ((opt[:format].to_s.downcase == 'html') if opt.is_a?(Hash)) ||
      (request.format.html? if defined?(request))
  end

  # Indicate whether the ultimate target format is something other than HTML.
  #
  # @param [Hash, nil] opt
  #
  def rendering_non_html?(opt)
    !rendering_html?(opt)
  end

  # Indicate whether the ultimate target format is JSON.
  #
  # @param [Hash, nil] opt
  #
  def rendering_json?(opt)
    ((opt[:format].to_s.downcase == 'json') if opt.is_a?(Hash)) ||
      (request.format.json? if defined?(request))
  end

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  public

  # Configuration :helper_method to display a URL as a clickable link for HTML
  # response format, or as one or more URLs for JSON response format.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]    If request.format.html?
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If !request.format.html?
  # @return [String]                              If !request.format.html?
  # @return [nil]                                 If no URLs were present.
  #
  # @see self#extract_config_value
  #
  def url_link(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).map { |v| v&.split('|', -3) }
    if rendering_non_html?(opt)
      result.map!(&:first)
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      separator = opt[:separator] || ' '
      result.map! { |url, _, label| outlink((label.presence || url), url) }
      result.join(separator).html_safe
    else
      return_empty(__method__)
    end
  end

  # Configuration :helper_method to display a DOI as a clickable link for HTML
  # response format only.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]    If request.format.html?
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If !request.format.html?
  # @return [String]                              If !request.format.html?
  # @return [nil]                                 If no URLs were present.
  #
  # @see self#extract_config_value
  #
  def doi_link(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    if rendering_non_html?(opt)
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      separator = opt[:separator] || "<br/>\n"
      result.map! { |v| outlink(v.sub(%r{^https?://.*doi\.org/}, ''), v) }
      result.join(separator).html_safe
    else
      return_empty(__method__)
    end
  end

  # Configuration :helper_method to display search term(s) as a clickable link
  # for HTML response format only.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]    If request.format.html?
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If !request.format.html?
  # @return [String]                              If !request.format.html?
  # @return [nil]                                 If no terms were present.
  #
  # @see self#extract_config_value
  #
  def search_link(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    if rendering_non_html?(opt)
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      separator = opt[:separator] || "<br/>\n"
      result.map { |terms|
        path_opt = search_state.to_h.except(:page, :action, :id)
        #path_opt[:q] = terms.match?(/\s/) ? %Q("#{terms}") : terms
        path_opt[:q] = terms
        link_to(terms, search_action_path(path_opt))
      }.join(separator).html_safe
    else
      return_empty(__method__)
    end
  end

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  protected

  # extract_config_options
  #
  # @param [Hash]      value
  # @param [Hash, nil] opt
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [Array<(String, Hash)>]
  # @return [Array<(Array<String>, Hash)>]
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def extract_config_value(value, opt = nil)
    opt ||= {}
    case value
      when Hash, Blacklight::Configuration::Field
        opt   = value.merge(extract_config_options(value[:config], opt))
        value = value[:value]
      when Array
        opt   = opt.merge(separator: HTML_NEW_LINE) unless opt.key?(:separator)
    end
    [value, opt]
  end

  # extract_config_options
  #
  # @param [Hash]      config
  # @param [Hash, nil] opt
  #
  # @option config [Hash]   :html_options        See below.
  # @option config [Hash]   :separator_options   See below.
  # @option config [String] :separator
  #
  # @option opt    [String] :separator
  #
  # @return [Hash]
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def extract_config_options(config, opt = nil)
    opt ||= {}
    if config.present?
      opt = opt.merge(config[:html_options] || {})
      if config.key?(:separator)
        opt.merge!(separator: config[:separator])
      elsif config[:separator_options].present?
        opt.merge!(separator: config[:separator_options].first.last)
      end
    end
    opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Return either #NO_LINK_DISPLAY or *nil*.
  #
  # @param [Symbol] method
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If directed by #RETURN_NIL
  #
  # @see self#NO_LINK_DISPLAY
  # @see self#RETURN_NIL
  #
  def return_empty(method)
    NO_LINK_DISPLAY unless RETURN_NIL[method]
  end

end

__loading_end(__FILE__)

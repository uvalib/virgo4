# app/helpers/about_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AboutHelper::Common
#
# @see AboutHelper
#
module AboutHelper::Common

  # Table cell display for blank/missing data.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  MISSING = '&mdash;'.html_safe.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Lookup or generate a topic heading.
  #
  # @param [Symbol] topic
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def topic_heading(topic)
    default = "#{topic.to_s.humanize.capitalize} Codes"
    scope   = "blacklight.about.#{topic}"
    I18n.t(:title, scope: scope, default: [:label, default]).html_safe
  end

  # Wraps a name-value pair in <span> tags inside a paragraph element.
  #
  # @param [String]    name
  # @param [String]    value
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def show_entry(name, value, opt = nil)
    html_opt = { class: 'about-entry' }
    merge_html_options!(html_opt, opt)
    name  = name.to_s
    value = value.inspect unless value&.html_safe?
    content_tag(:p, html_opt) {
      content_tag(:span, ERB::Util.h(name),  class: 'about-item') +
      content_tag(:span, ERB::Util.h(value), class: 'about-value')
    }
  end

  # Produces elements for a set of name-value pairs.
  #
  # @param [Hash]               table
  # @param [Array<String>, nil] featured
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_entries(table, featured = nil)
    table.map { |name, value|
      opt = ({ class: 'featured' } if featured&.include?(name))
      show_entry(name, value, opt)
    }.join("\n").html_safe
  end

  # Allow control button definitions to include I18n symbols that will be
  # replaced with the appropriately-scoped locale value.
  #
  # @param [Symbol]             feature
  # @param [Hash{Symbol=>Hash}] hash
  # @param [Hash, nil]          t_opt   I18n options
  #
  # @return [Hash{String=>Hash}]
  #
  def form_controls(feature, hash, t_opt = nil)
    hash ||= {}
    t_opt = t_opt ? t_opt.dup : {}
    t_opt[:scope] ||= "blacklight.about.#{feature}"
    t_opt[:raise] = false unless t_opt.key?(:raise)
    hash.map { |control, opt|

      # Button label.
      scope = t_opt.merge(scope: "#{t_opt[:scope]}.#{control}.control")
      if control.is_a?(Symbol)
        default = [:title, control.to_s.humanize.capitalize]
        control = I18n.t(:label, scope.merge(default: default))
      end

      # Button options.
      if opt[:title].is_a?(Symbol)
        opt[:title] = I18n.t(:tooltip, scope)
      end
      if opt[:'data-confirm'].is_a?(Symbol)
        opt[:'data-confirm'] = I18n.t(:confirm, scope)
      end
      if opt[:data].is_a?(Hash) && opt[:data][:confirm].is_a?(Symbol)
        opt[:data][:confirm] = I18n.t(:confirm, scope)
      end

      # Ensure that UrlHelper#button_to sees :method the way it requires.
      opt[:method] = opt[:method].to_s.downcase if opt[:method].present?
      opt[:method] ||= 'get'

      [control, opt]
    }.to_h
  end

  # sidebar_controls
  #
  # @param [Hash{Symbol=>String}] pages
  #
  # @return [Hash{String=>Hash}]
  #
  def sidebar_controls(pages)
    pages.flat_map { |page, path|
      next if path.blank?
      buttons = []
      scope = 'blacklight.about'
      case page
        when :main       then # OK as is.
        when :solr_stats then scope += '.solr.stats'
        else                  scope += ".#{page}"
      end
      t_opt = { scope: scope, app: application_name, raise: false }

      # Determine label and tooltip for the control.
      default = (page == :main) ? 'About' : page.to_s
      label   = [:label, :page_title, default]
      label   = I18n.t('control.label',   t_opt.merge(default: label) )
      tooltip = I18n.t('control.tooltip', t_opt.merge(default: [:tooltip, '']))
      buttons << [label, { path: path, tooltip: tooltip }]

      # Incorporate additional controls if warranted.
      if (request.path == path) && %i(solr log).include?(page)
        buttons << [page, { path: "about/#{page}/controls" }]
      end

      buttons
    }.to_h
  end

end

__loading_end(__FILE__)

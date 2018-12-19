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

  # Blacklight field types.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see self#get_solr_fields
  #
  FIELD_TYPES = I18n.t('blacklight.about.solr.fields.types').keys.deep_freeze

  # ===========================================================================
  # :section: About pages
  # ===========================================================================

  public

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

  # Produces a <table> from an Enumerable.
  #
  # If *table* is a Hash then a two-column table is generated, containing
  # <colgroup> and <thead> elements (unless the equivalent arguments are passed
  # in as *false*).
  #
  # If *table* is an Array then a one-column table is generated (without
  # <colgroup> or <thead> elements)
  #
  # @param [Hash, Array]    table
  # @param [String, Symbol] repository    Either :solr or :eds; default: *nil*.
  # @param [Boolean]        nested        Default: nil
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_table(table, repository: nil, nested: nil)

    columns   = %w(Item Value)
    prefix    = repository ? "about-#{repository}" : 'about'
    div_opt   = { class: "#{prefix}-table-container" }
    table_opt = { class: "#{prefix}-table" }

    if table.is_a?(Hash)
      # Turn off <thead> if nested.
      table_opt[:class] += ' nested' if nested
      thead    = !nested
      colgroup = true
    else
      # Translate the array into a key/value pair form that will be iterated
      # over the same way a Hash is.
      unless table.is_a?(Array)
        logger.warn { "#{__method__}: #{table.class}: should be Enumerable" }
      end
      table = Array.wrap(table).map { |v| [nil, v] }
      thead = colgroup = false
    end

    # The <table> element inside a container.
    content_tag(:div, div_opt) do
      content_tag(:table, table_opt) do

        # Define columns with a distinct CSS class for styling.
        colgroup &&=
          content_tag(:colgroup) do
            (1..columns.size).map { |i|
              content_tag(:col, '', class: "col#{i}")
            }.join.html_safe
          end

        # Table header if requested and table is a hash.
        thead &&=
          content_tag(:thead) do
            columns.map { |x|
              content_tag(:th, h(x), class: 'heading')
            }.join.html_safe
          end

        # Table body in which Enumerable values are handled as nested tables.
        tbody =
          content_tag(:tbody) do
            table.map { |k, v|
              nested_table =
                case v
                  when Hash  then v.present?
                  when Array then v.first.is_a?(Enumerable) || (v.size > 2)
                end
              content_tag(:tr) do
                k = k&.to_s
                v = nested_table ? show_table(v, nested: true) : v.inspect
                [k, v].map { |x|
                  content_tag(:td, h(x), class: 'cell') if x
                }.join.html_safe
              end
            }.join("\n").html_safe
          end

        [colgroup, thead, tbody].reject(&:blank?).join("\n").html_safe
      end
    end
  end

  # A menu element to choose a lens to use in comparisons between Solr fields
  # and configured Blacklight fields.
  #
  # @param [String, Symbol] selected  The lens to show as selected.
  # @param [String]         path      Default: `request.path`
  # @param [String]         prompt    Default: "Lens"
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def lens_select_menu(selected: nil, path: request.path, prompt: nil)
    prompt ||= I18n.t('blacklight.about.select.label', default: 'Lens')
    menu = Blacklight::Lens.lens_keys.map { |k| [k.to_s.capitalize, k.to_s] }
    menu = menu.unshift([prompt, ''])
    menu = options_for_select(menu, selected.to_s)
    form_tag(path, method: :get, class: 'about-lens-select') do
      select_opt = { class: 'form-control', onchange: 'this.form.submit();' }
      select_tag(:lens, menu, select_opt)
    end
  end

  # Icon for the search repository field table that indicates that the selected
  # lens configuration does not include the associated repository field.
  #
  # If the :repository argument is given, the icon is produced with a tooltip
  # that explains the meaning of the icon relative to that search repository.
  #
  # @param [Symbol, String] repository        Default: *nil*
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def in_this_lens(repository: nil)
    opt = { class: 'in-this-lens' }
    if repository.present?
      search = repository_label(repository)
      opt[:title] = "The lens configuration includes this #{search} field"
    end
    blacklight_icon('ok', opt)
  end

  # Icon for the search repository field table that indicates that the selected
  # lens configuration does not include the associated repository field.
  #
  # If the :repository argument is given, the icon is produced with a tooltip
  # that explains the meaning of the icon relative to that search repository.
  #
  # @param [Symbol, String] repository        Default: *nil*
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def not_this_lens(repository: nil)
    opt = { class: 'not-this-lens' }
    if repository.present?
      search = repository_label(repository)
      opt[:title] =
        "The lens configuration does not include this #{search} field"
    end
    blacklight_icon('remove', opt)
  end

  # Icon for the search repository field table that indicates that no lens
  # configuration includes the associated repository field.
  #
  # If the :repository argument is given, the icon is produced with a tooltip
  # that explains the meaning of the icon relative to that search repository.
  #
  # @param [Symbol, String] repository        Default: *nil*
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def not_any_lens(repository: nil)
    opt = { class: 'not-any-lens' }
    if repository.present?
      search = repository_label(repository)
      opt[:title] = "No lens configuration includes this #{search} field"
    end
    blacklight_icon('remove', opt)
  end

  # Convert a symbol or string to a uniform search repository name.
  #
  # @param [String, Symbol] value
  #
  # @return [String]
  #
  def repository_label(value)
    identifier =
      if value.is_a?(Symbol)
        value
      elsif (v = value.to_s.downcase).include?('solr')
        :solr
      elsif v.include?('ebsco') || v.include?('eds')
        :eds
      end
    case identifier
      when :solr then 'Solr'
      when :eds  then 'EBSCO EDS'
      else            "Unknown (#{value})"
    end
  end

  # Indicate whether the given field name is in the current configuration.
  #
  # @param [Symbol]                         field
  # @param [Symbol, Array<Symbol>]          type    One or more of
  #                                                   `FIELD_TYPES`;
  #                                                   default: all types.
  # @param [Blacklight::Configuration, nil] config  Default value is
  #                                                 `default_blacklight_config`
  #
  # @see self#FIELD_TYPES
  #
  def in_configuration?(field, type: type, config: config)
    config ||= default_blacklight_config
    type = type ? Array.wrap(type) : FIELD_TYPES
    case type
      when [:sort]
        config.sort_field?(field)
      when [:facet]
        config.facet_field?(field)
      when [:display], [:suggest]
        config.index_field?(field) || config.show_field?(field)
      else
        (type.include?(:sort)  && config.sort_field?(field))  ||
        (type.include?(:facet) && config.facet_field?(field)) ||
        (config.index_field?(field) || config.show_field?(field))
    end
  end

  # ===========================================================================
  # :section: About sidebar
  # ===========================================================================

  public

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
      main   = (page == :main)
      scope  = 'blacklight.about'
      scope += ".#{page}" unless main
      t_opt  = { scope: scope, app: application_name, raise: false }

      # Determine label and tooltip for the control.
      label   = [:label, :page_title, (main ? 'About' : page.to_s)]
      label   = I18n.t('control.label',   t_opt.merge(default: label) )
      tooltip = I18n.t('control.tooltip', t_opt.merge(default: [:tooltip, '']))
      buttons << [label, { path: path, tooltip: tooltip }]

      # Incorporate additional controls if warranted.
      if (request.path == path) && %i(solr eds log).include?(page)
        buttons << [page, { path: "about/#{page}/controls" }]
      end

      buttons
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Make a copy of *hash* which contains only the portions of the original that
  # match the structure of *template*.  At any level of the hierarchy, the
  # ordering of keys in *template* defines the ordering of keys in the result.
  #
  # @param [Hash] hash
  # @param [Hash] template
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def deep_slice(hash, template)
    hash ||= {}
    keys = template&.keys || []
    hash.slice(*keys).map { |k, v|
      if v.is_a?(Hash) && template[k].is_a?(Hash)
        v = deep_slice(v, template[k])
      elsif logger.debug?
        # If `template[k]` is *nil* then that indicates that all of `v[k]` is
        # intended to be included in the result so no need for a debug message.
        unless (expected = template[k].class).nil? || v.is_a?(expected)
          logger.debug {
            "#{__method__}: #{k}: expected #{expected}; data is #{v.class}"
          }
        end
      end
      [k, v]
    }.to_h
  end

  # Return an array of values which is exactly the same size as `keys.size` so
  # that a hash can be used to initialize variables.
  #
  # @param [Hash]                 hash
  # @param [Array<String,Symbol>] keys
  #
  # @return [Array]
  # @return [nil]                     If *hash* is not a Hash.
  #
  def value_array(hash, *keys)
    return unless hash.is_a?(Hash)
    keys.flatten!
    keys.map { |v| [v, nil] }.to_h.merge(hash).slice(*keys).values
  end

end

__loading_end(__FILE__)

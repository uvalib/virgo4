# app/helpers/about_helper/solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'curb'

# AboutHelper::Solr
#
# @see AboutHelper
#
module AboutHelper::Solr

  include AboutHelper::Common

  def self.included(base)
    __included(base, '[AboutHelper::Solr]')
  end

  # A table of the Solr field name suffixes for each Blacklight field type.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see self#get_solr_fields
  #
  SOLR_TYPES =
    I18n.t('blacklight.about.solr.fields.types').deep_freeze

  # Definitions of the parts of the JSON returned from the Solr luke handler.
  #
  # @type [Hash{Symbol=>*}]
  #
  # @see self#get_solr_statistics
  #
  SOLR_STATS_DATA_TEMPLATE =
    I18n.t('blacklight.about.solr.stats.data_template').deep_freeze

  # Definitions of the parts of the JSON returned from the Solr luke handler.
  #
  # @type [Array<Hash{Symbol=>String}>]
  #
  # @see self#solr_stats_columns
  #
  SOLR_STATS_COLUMNS =
    I18n.t('blacklight.about.solr.stats.columns').deep_freeze

  # Definitions of the parts of the JSON returned from the Solr luke handler.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see self#get_solr_information
  #
  SOLR_INFO_DATA_TEMPLATE =
    I18n.t('blacklight.about.solr.info.data_template').deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get Solr fields organized by Blacklight field type.
  #
  # @return [Hash{Symbol=>Hash{Symbol=>Hash}}]
  #
  # @see self#SOLR_TYPES
  # @see self#get_solr_field_data
  #
  def get_solr_fields
    fields       = get_solr_field_data
    lens_keys    = Blacklight::Lens.lens_keys
    lens_configs = lens_keys.map { |k| [k, blacklight_config_for(k)] }.to_h
    SOLR_TYPES.map { |type, entry|
      suffix, show_as =
        entry.is_a?(Hash) ? entry.slice(:suffix, :show_as).values : entry.to_s
      table =
        fields.map { |field, count|
          field = field.to_s
          next unless field.end_with?(suffix)
          data = { count: count }
          field, variant =
            show_as ? [field.sub(/#{suffix}$/, show_as), field] : field
          data[:lenses] =
            lens_configs.select { |_, config|
              options = { type: type, config: config }
              in_configuration?(field, options) ||
                (in_configuration?(variant, options) if variant)
            }.keys
          [field, data]
        }.compact.to_h
      [type, table]
    }.to_h
  end

  # Get administrative information from Solr.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # @see self#SOLR_INFO_DATA_TEMPLATE
  # @see self#get_solr_admin_data
  #
  def get_solr_information
    SOLR_INFO_DATA_TEMPLATE.map { |route, template|
      [route, get_solr_admin_data(route, template)]
    }.to_h
  end

  # Get statistics about each field defined by Solr.
  #
  # @return [Hash{Symbol=>Hash{Symbol=>Hash}}]
  #
  # @see self#get_solr_field_stats
  #
  def get_solr_statistics
    get_solr_field_stats.tap do |results|
      results.each_pair do |_, entry|
        next if (h = entry[:histogram]).blank?
        entry[:histogram] = Hash[*h]
      end
    end
  end

  # Indicate whether the given field name is in the current configuration.
  #
  # @param [Symbol]                         field
  # @param [Symbol, Array<Symbol>]          type    One or more of
  #                                                   `SOLR_TYPES.keys`;
  #                                                   default: all types.
  # @param [Blacklight::Configuration, nil] config  Default value is
  #                                                 `default_blacklight_config`
  #
  def in_configuration?(field, type: type, config: config)
    config ||= default_blacklight_config
    type   ||= SOLR_TYPES.keys
    type     = Array.wrap(type)
    case type
      when [:sort]
        config.sort_field?(field)
      when [:facet]
        config.facet_field?(field)
      when [:display], [:suggest]
        config.index_field?(field) || config.show_field?(field)
      else
        (type.include?(:sort)  && config.sort_field?(field)) ||
        (type.include?(:facet) && config.facet_field?(field)) ||
        (config.index_field?(field) || config.show_field?(field))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A menu element to choose a lens to use in comparisons between Solr fields
  # and configured Blacklight fields.
  #
  # @param [String, nil] selected_lens
  # @param [String, nil] path           Default: `request.path`
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def lens_select_menu(selected_lens = nil, path = nil)
    keys   = Blacklight::Lens.lens_keys.map(&:to_s)
    table  = keys.map { |k| [k.capitalize, k] }
    prompt = I18n.t('blacklight.about.solr.select.label', default: 'Lens')
    menu   = table.unshift([prompt, ''])
    menu   = options_for_select(menu, selected_lens.to_s)
    path ||= request.path
    form_tag(path, method: :get, class: 'about-lens-select') do
      select_opt = { class: 'form-control', onchange: 'this.form.submit();' }
      select_tag(:lens, menu, select_opt)
    end
  end

  # Icon for the Solr field table that indicates that the selected lens
  # configuration does not include the associated Solr field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def not_this_lens
    blacklight_icon(
      'remove',
      title: 'The lens configuration does not include this Solr field'
    )
  end

  # Icon for the Solr field table that indicates that no lens configuration
  # includes the associated Solr field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def not_any_lens
    blacklight_icon(
      'remove',
      class: 'text-light bg-danger',
      title: 'No lens configuration includes this Solr field'
    )
  end

  # Link to the indicated portion of the '/about/solr_stats' page.
  #
  # @param [String]    name
  # @param [Hash, nil] opt
  #
  # @option opt [String] :title       For no tooltip, explicitly set to *nil*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def solr_stats_link(name, opt = nil)
    link_opt = {}
    if opt&.key?(:title)
      opt = opt.except(:title) if opt[:title].blank?
    else
      tooltip =
        'A link to the field on the solr_stats page.' \
        "\nWARNING: Takes at least 10 seconds to complete if not cached."
      opt = (opt || {}).merge(title: tooltip)
    end
    merge_html_options!(link_opt, opt)
    name = name.to_s
    url  = about_solr_stats_path(anchor: name)
    link_to(h(name), url, link_opt)
  end

  # Convenience link to the definition of a Solr field.
  #
  # @param [String] name
  # @param [Hash, nil] opt
  #
  # @option opt [String] :title       For no tooltip, explicitly set to *nil*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def solr_field_info_link(name, opt = nil)
    link_opt = { target: '_blank' }
    if opt&.key?(:title)
      opt = opt.except(:title) if opt[:title].blank?
    else
      tooltip = 'Links to the Solr administrative page for the field.'
      opt = (opt || {}).merge(title: tooltip)
    end
    merge_html_options!(link_opt, opt)
    name = name.to_s
    url  = "#{solr_url(true)}/schema?field=#{name}"
    link_to(h(name), url, link_opt)
  end

  # Solr sidebar control buttons.
  #
  # @param [Hash{Symbol=>Hash}]
  #
  # @return [Hash{String=>Hash}]
  #
  def solr_controls(hash)
    form_controls(:solr, hash)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # solr_stats_columns
  #
  # @return [Array<Hash{Symbol=>String}>]
  #
  # @see self#SOLR_STATS_COLUMNS
  #
  def solr_stats_columns
    idx = 0
    @solr_stats_columns ||=
      SOLR_STATS_COLUMNS.map do |entry|
        label = entry[:label].presence
        label = label ? h(label) : idx.to_s
        tooltip   = entry[:tooltip].presence
        tooltip &&= h(tooltip)
        idx += 1
        { label: label, tooltip: tooltip }
      end
  end

  # solr_stats_header_row
  #
  # @param [Hash, nil] opt            Options to merge into outer HTML options.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see self#solr_stats_columns
  #
  def solr_stats_header_row(opt = nil)
    outer_opt = { class: 'heading-row' }
    merge_html_options!(outer_opt, opt)
    content_tag(:tr, outer_opt) do
      solr_stats_columns.map { |entry|
        opt = { class: 'heading' }
        opt[:title] = entry[:tooltip] if entry[:tooltip].present?
        content_tag(:th, entry[:label], opt)
      }.join("\n").html_safe
    end
  end

  # solr_stats_histogram_headers
  #
  # @param [Numeric] max              Maximum power of 2.
  #
  # @return [Array<Hash{Symbol=>Numeric,Symbol=>String}>]
  #
  def solr_stats_histogram_columns(max = 24)
    previous = nil
    @solr_stats_histogram_columns ||=
      (0..max).map do |n|
        upper_bound = 2 ** n
        docs =
          case upper_bound
            when 1 then 'a single document'
            when 2 then 'two documents'
            when 4 then 'three or four documents'
            else        "#{previous + 1} to #{upper_bound} documents"
          end
        tooltip  = "Portion of unique terms for this field that are in #{docs}"
        previous = upper_bound
        { upper_bound: upper_bound, tooltip: tooltip }
      end
  end

  # solr_stats_histogram_headers
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see self#solr_stats_columns
  #
  def solr_stats_histogram_headers
    content_tag(:table, class: 'about-histogram') do
      content_tag(:thead) do
        content_tag(:tr) do
          solr_stats_histogram_columns.map { |entry|
            content_tag(:th, entry[:upper_bound], title: entry[:tooltip])
          }.join("\n").html_safe
        end
      end
    end
  end

  # solr_stats_row
  #
  # @param [String, Symbol] field
  # @param [Hash]           data
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see self#solr_stats_histogram
  #
  def solr_stats_row(field, data)
    total = data[:distinct].to_f
    data  = data.reverse_merge(field: solr_field_info_link(field))
    content_tag(:tr, id: h(field.to_s.parameterize)) do
      data.map { |k, v|
        content_tag(:td, class: "cell data-#{k.to_s.parameterize}") do
          (k == :histogram) ? solr_stats_histogram(v, total) : h(v)
        end
      }.join("\n").html_safe
    end
  end

  # solr_stats_histogram
  #
  # @param [Hash]  data
  # @param [Float] total
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def solr_stats_histogram(data, total)
    header      = solr_stats_histogram_columns
    empty_count = header.size - data.size
    pct_fmt  = '%2.1f%%'
    epsilon  = 0.001
    bg_color = '#206652'
    fg_color = 'white'
    content_tag(:table, class: 'about-histogram') do
      content_tag(:tbody) do
        content_tag(:tr) do
          idx = 0
          columns =
            data.map do |_, count|
              opt = {}
              format  = pct_fmt
              percent = count / total
              if percent.zero?
                opt[:class] = 'zero'
              elsif percent < epsilon
                format  = "< #{format}"
                percent = epsilon
              end
              style = "background-color: #{bg_color}%02x;" % (percent * 255)
              style << "color: #{fg_color};" if percent >= 0.5
              opt[:style] = style
              tooltip = header[idx][:tooltip].dup
              tooltip << " (#{count} #{'term'.pluralize(count)})"
              opt[:title] = tooltip
              idx += 1
              content_tag(:td, opt) do
                format % (percent * 100)
              end
            end
          columns += empty_count.times.map { content_tag(:td) }
          columns.join.html_safe
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a table of the fields defined in the Solr instance along with the count
  # of documents that have that field (or *nil* for non-indexed field types).
  #
  # @return [Hash{String=>Numeric}]
  # @return [Hash{String=>nil}]
  #
  # @see https://wiki.apache.org/solr/LukeRequestHandler
  #
  def get_solr_field_data
    data = get_solr_data_luke
    data.map { |field, entry| [field, entry[:docs].presence] }.to_h
  end

  # Get a table of all of the fields defined in the Solr instance along with
  # the total number of distinct values for the field and a histogram of the
  # number of occurrences per document.
  #
  # In the returned hash, each value may contain:
  #
  #   [String]  :type
  #   [String]  :index
  #   [Numeric] :docs
  #   [Numeric] :distinct
  #   [Hash]    :histogram
  #
  # Any of this fields may be missing; for '_a' fields only :type will be
  # present.
  #
  # @param [Hash, nil] template       A hash which defines the keys to be
  #                                     selected from the data.
  #
  # @return [Hash{String=>Hash}]
  #
  # @see self#SOLR_STATS_DATA_TEMPLATE
  # @see https://wiki.apache.org/solr/LukeRequestHandler
  #
  def get_solr_field_stats(template = nil)
    data = get_solr_data_luke(fl: '*', numTerms: 0)
    template ||= SOLR_STATS_DATA_TEMPLATE
    data.map { |field, entry| [field, deep_slice(entry, template)] }.to_h
  end

  # get_solr_admin_data
  #
  # @param [String, Symbol] route     The last portion of the Solr request URL.
  # @param [Hash, nil]      template  A hash which defines the keys to be
  #                                     selected from the data.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def get_solr_admin_data(route, template = nil)
    data = get_solr_data(route)
    template ||= SOLR_INFO_DATA_TEMPLATE[route.to_sym]
    deep_slice(data, template)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return a Hash from JSON data returned from Solr.
  #
  # @param [String, Symbol] route     The last portion of the Solr request URL.
  # @param [Hash, nil]      opt       Options to JSON#parse.
  #
  # @return [Hash]
  #
  def get_solr_data(route, opt = nil)
    http = Curl.get("#{solr_url}/#{route}")
    data = http.body_str
    opt  = (opt || {}).reverse_merge(symbolize_names: true)
    JSON.parse(data, opt) || {}
  end

  # Return a Hash from JSON data returned from Solr.
  #
  # @param [Hash, Array, String, nil] url_params  Solr URL parameters
  # @param [Hash, nil]                opt         Options to JSON#parse.
  #
  # @return [Hash]
  #
  def get_solr_data_luke(url_params = nil, opt = nil)
    route = 'admin/luke'
    if url_params.present?
      route += (route.include?('?') ? '&' : '?')
      route <<
        if url_params.is_a?(Hash)
          url_params.to_query
        else
          Array.wrap(url_params).join('&')
        end
    end
    get_solr_data(route, opt)[:fields] || {}
  end

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

  # The base path to Solr for constructing requests.
  #
  # @param [Boolean] interactive      If *true*, use the path to the
  #                                     interactive web page.
  #
  # @return [String]
  #
  # TODO: Retrieve from blacklight.yml
  #
  def solr_url(interactive = false)
    proto = 'http'
    host  = 'junco.lib.virginia.edu'
    port  = '8080'
    path  = ["#{proto}://#{host}:#{port}"]
    path << 'solr'
    path << '#' if interactive
    path << 'test_core'
    path.join('/')
  end

end

__loading_end(__FILE__)

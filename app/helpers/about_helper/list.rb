# app/helpers/about_helper/list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AboutHelper::List
#
# @see AboutHelper
#
module AboutHelper::List

  include AboutHelper::Common
  extend  AboutHelper::Common

  def self.included(base)
    __included(base, '[AboutHelper::List]')
  end

  # The heading for the library list page.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  LIBRARY_HEADING = topic_heading(:library).freeze

  # The heading for the location list page.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  LOCATION_HEADING = topic_heading(:location).freeze

  # The description for the library list page that appears below the heading.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  LIBRARY_DESCRIPTION =
    I18n.t('blacklight.about.library.description').html_safe.freeze

  # The description for the location list page that appears below the heading.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  LOCATION_DESCRIPTION =
    I18n.t('blacklight.about.location.description').html_safe.freeze

  # Column headers for the library list page.
  #
  # @type [Array<ActiveSupport::SafeBuffer>]
  #
  LIBRARY_COLUMNS =
    I18n.t('blacklight.about.library.columns').map(&:html_safe).deep_freeze

  # Column headers for the location list page.
  #
  # @type [Array<ActiveSupport::SafeBuffer>]
  #
  LOCATION_COLUMNS =
    I18n.t('blacklight.about.location.columns').map(&:html_safe).deep_freeze

  # ===========================================================================
  # :section: List library page
  # ===========================================================================

  public

  # The heading for the library list page.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def library_heading
    LIBRARY_HEADING
  end

  # Text describing the library list.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def library_description
    LIBRARY_DESCRIPTION
  end

  # Column headers for the library list.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def library_heading_row
    content_tag(:tr) do
      content_tags(:th, *LIBRARY_COLUMNS, class: 'heading')
    end
  end

  # Table rows for the library list.
  #
  # @param [Firehose::LibraryList] list
  # @param [Hash]                  opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def library_rows(list, opt = nil)
    html_opt = { class: 'data' }
    merge_html_options!(html_opt, opt)
=begin # TODO: Firehose
    list.libraries
      .sort { |a, b| a.id.to_i <=> b.id.to_i }
      .map do |library|
        entry = [
          library.id,
          library.code,
          library.name,
          library.leoable?,
          library.deliverable?,
          library.holdable?,
          library.remote?
        ].map { |v| v.presence || MISSING }
        content_tag(:tr) do
          content_tags(:td, *entry, html_opt)
        end
      end
=end
    list.map do |library| # NOTE: temporary; to be removed
      entry = [library] + ([MISSING] * (LIBRARY_COLUMNS.size - 1))
      content_tag(:tr) do
        content_tags(:td, *entry, html_opt)
      end
    end
  end

  # ===========================================================================
  # :section: List location page
  # ===========================================================================

  public

  # The heading for the location list page.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def location_heading
    LOCATION_HEADING
  end

  # Text describing the location list.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def location_description
    LOCATION_DESCRIPTION
  end

  # Column headers for the location list.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def location_heading_row
    content_tag(:tr) do
      content_tags(:th, *LOCATION_COLUMNS, class: 'heading')
    end
  end

  # Table rows for the location list.
  #
  # @param [Firehose::LocationList] list
  # @param [Hash]                   opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def location_rows(list, opt = nil)
    html_opt = { class: 'data' }
    merge_html_options!(html_opt, opt)
=begin # TODO: Firehose
    list.locations
      .sort { |a, b| a.id.to_i <=> b.id.to_i }
      .map do |loc|
        entry = [loc.id, loc.code, loc.name].map { |v| v.presence || MISSING }
        content_tag(:tr) do
          content_tags(:td, *entry, html_opt)
        end
      end
=end
    list.map do |loc| # NOTE: temporary; to be removed
      entry = [loc] + ([MISSING] * (LOCATION_COLUMNS.size - 1))
      content_tag(:tr) do
        content_tags(:td, *entry, html_opt)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # topic_components
  #
  # @param [Symbol] topic
  # @param [Array]  topic_list
  #
  # @return [Array<(
  #   ActiveSupport::SafeBuffer,
  #   ActiveSupport::SafeBuffer,
  #   ActiveSupport::SafeBuffer,
  #   Array<ActiveSupport::SafeBuffer>
  # )>]
  #
  def topic_components(topic, topic_list)
    result = []
    result << send("#{topic}_heading")
    result << send("#{topic}_description")
    result << send("#{topic}_heading_row")
    result << send("#{topic}_rows", topic_list)
  rescue => e
    $stderr.puts ">>> #{e.inspect}"
    default = [
      'Unknown',
      %Q(No information on "#{topic.to_s.humanize.capitalize}"),
      nil,
      []
    ]
    (1..default.size).map do |i|
      (result.size < i) ? default[i - 1] : result[i - 1]
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Wrap each argument in an HTML element of the indicated type.
  #
  # @param [Symbol, String] tag
  # @param [Array<String>]  args
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def content_tags(tag, *args)
    html_opt = args.last.is_a?(Hash) ? args.pop : {}
    args.map { |arg| content_tag(tag, arg, html_opt) }.join.html_safe
  end

end

__loading_end(__FILE__)

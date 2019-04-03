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

  extend self

  def self.included(base)
    __included(base, '[AboutHelper::List]')
  end

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
      column_tags(:th, *LIBRARY_COLUMNS, class: 'heading')
    end
  end

  # Table rows for the library list.
  #
  # @param [IlsLibraryList, Array<Ils::Library>] list
  # @param [Hash, nil]                           opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def library_rows(list, opt = nil)
    html_opt = { class: 'data' }
    merge_html_options!(html_opt, opt)
    list = list.libraries if list.is_a?(IlsLibraryList)
    list
      .sort { |a, b| a.id.to_i <=> b.id.to_i }
      .map do |library|
        content_tag(:tr) do
          columns = [
            library.id,
            library.code,
            library.name,
            library.leoable?,
            library.deliverable?,
            library.holdable?,
            library.remote?
          ]
          column_tags(:td, *columns, html_opt)
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
      column_tags(:th, *LOCATION_COLUMNS, class: 'heading')
    end
  end

  # Table rows for the location list.
  #
  # @param [IlsLocationList, Array<Ils::Library>] list
  # @param [Hash, nil]                            opt
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def location_rows(list, opt = nil)
    html_opt = { class: 'data' }
    merge_html_options!(html_opt, opt)
    list = list.locations if list.is_a?(IlsLocationList)
    list
      .sort { |a, b| a.id.to_i <=> b.id.to_i }
      .map do |loc|
        content_tag(:tr) do
          column_tags(:td, loc.id, loc.code, loc.name, html_opt)
        end
      end
  end

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
    scope   = "blacklight.about.#{topic}"
    default = "#{topic.to_s.humanize.capitalize} Codes"
    I18n.t(:title, scope: scope, default: [:label, default]).html_safe
  end

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
  def column_tags(tag, *args)
    html_opt = args.last.is_a?(Hash) ? args.pop : {}
    args.map { |arg|
      content_tag(tag, (arg || MISSING), html_opt)
    }.join.html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

end

__loading_end(__FILE__)

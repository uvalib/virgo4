# app/helpers/layout_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::LayoutHelperBehavior
#
module LayoutHelper

  include Blacklight::LayoutHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[LayoutHelper]')
  end

  META_TAG_SEPARATOR = "\n  "

  EXTERNAL_FONTS = %w(
    //fonts.googleapis.com/css?family=Cardo:400,700
    //maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css
  ).freeze

  DEFAULT_JQUERY = nil
=begin # TODO: jQuery version in use is 1.12.4
    DEFAULT_JQUERY =
      '//ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js'
=end

  EXTERNAL_SCRIPTS = %W(
  ).reject(&:blank?).freeze
=begin # TODO: Piwik
    EXTERNAL_SCRIPTS = %W(
      //use.typekit.com/dcu6kro.js
      #{Piwik.script}
    ).reject(&:blank?).freeze
=end

  # This script is being added as part of a UVA effort to analyze and improve
  # accessibility.
  #
  # @see https://levelaccess.com
  #
  ACCESS_ANALYTICS = nil
=begin # TODO: LevelAccess
    ACCESS_ANALYTICS = %q(
      <script type="text/javascript">
        var access_analytics={
        base_url:"https://analytics.ssbbartgroup.com/api/",
        instance_id:"AA-58bdcc11cee35"};(function(a,b,c){
        var d=a.createElement(b);a=a.getElementsByTagName(b)[0];
        d.src=c.base_url+"access.js?o="+c.instance_id+"&v=2";
        a.parentNode.insertBefore(d,a)})(document,"script",access_analytics);
      </script>
    ).squish.freeze
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # external_stylesheets
  #
  # @param [Array<String>] args     Added script URL's or literal tags.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # TODO: needs work
  #
  def external_stylesheets(*args)
    tags, paths = args.partition { |arg| arg.include?('<link') }
    paths = (EXTERNAL_FONTS + paths).reject(&:blank?)
    tags  = tags.reject(&:blank?).uniq.join(META_TAG_SEPARATOR).html_safe
    stylesheet_link_tag(*paths) + tags
  end

  # external_scripts
  #
  # @param [Array<String>] args     Added script URL's or literal tags.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # TODO: needs work
  #
  def external_scripts(*args)
    tags, paths = args.partition { |arg| arg.include?('<script') }
    paths = (EXTERNAL_SCRIPTS + [DEFAULT_JQUERY] + paths).reject(&:blank?)
    tags << ACCESS_ANALYTICS
    tags  = tags.reject(&:blank?).uniq.join(META_TAG_SEPARATOR).html_safe
    javascript_include_tag(*paths) + tags
  end

end

__loading_end(__FILE__)

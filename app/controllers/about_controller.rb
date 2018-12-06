# app/controllers/about_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Informational pages about this site and other related information.
#
# @see AboutHelper
# @see app/views/about
#
class AboutController < ApplicationController

  include AboutConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /about
  # The "About Virgo" page.
  #
  def index
  end

  # == GET /about/list/:topic
  # An informational listing on a given subject.
  #
  # == GET /about/list/library
  # == GET /about/list/libraries
  # == GET /about/list/location
  # == GET /about/list/locations
  #
  def list
    @topic      = get_topic(params)
    @topic_list = get_topic_list(@topic)
    respond_to do |format|
      format.html
      format.xml  { render xml:  @topic_list.to_xml }
      format.json { render json: @topic_list.to_json }
    end
  end

end

__loading_end(__FILE__)

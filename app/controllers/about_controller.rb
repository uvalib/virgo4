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
  # :section: Filter actions
  # ===========================================================================

  before_action :verify_session, only: %i(solr log log_wipe)

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

  # == GET /about/solr
  # == GET /about/solr?lens=:lens
  # Administrator-only Solr information.
  #
  def solr
    @solr_fields = get_solr_fields
    @solr_info   = get_solr_information
  end

  # == GET /about/solr_stats
  # Administrator-only Solr information.
  #
  def solr_stats
    @solr_stats = get_solr_statistics
    render 'about/solr'
  end

  # == GET /about/eds
  # Administrator-only EBSCO EDS information.
  #
  def eds
    @eds_session = get_eds_session
    @eds_fields  = get_eds_fields
  end

  # == GET /about/log
  # Administrator-only application log viewer.
  #
  def log
    count = default_log_lines(params)
    lines = get_file_lines(log: true, tail: count)
    respond_with(lines)
  end

  # == DELETE /about/log
  # Administrator-only command to wipe the application log.
  #
  def log_wipe
    lines = wipe_log
    respond_with(lines, template: 'about/log')
  end

end

__loading_end(__FILE__)

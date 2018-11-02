# app/models/search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# This extends the model defined in the Blacklight gem for lens-sensitivity.
#
class RecordMailer < ActionMailer::Base

  include Blacklight::Lens
  include Blacklight::Lens::Controller

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Send one or more documents via email.
  #
  # @param [LensDocument, Array<LensDocument>] docs
  # @param [Hash]                              details
  # @param [Hash]                              url_gen_params
  #
  def email_record(docs, details, url_gen_params)
    docs  = Array.wrap(docs)
    title =
      begin
        docs.first.to_semantic_values[:title]
      rescue
        I18n.t('blacklight.email.text.default_title')
      end
    subject =
      I18n.t('blacklight.email.text.subject', count: docs.size, title: title)
    @documents      = docs
    @message        = details[:message]
    @url_gen_params = url_gen_params
    mail(to: details[:to],  subject: subject)
  end

  # Send one or more documents via SMS text message.
  #
  # @param [LensDocument, Array<LensDocument>] docs
  # @param [Hash]                              details
  # @param [Hash]                              url_gen_params
  #
  def sms_record(docs, details, url_gen_params)
    @documents      = Array.wrap(docs)
    @url_gen_params = url_gen_params
    mail(to: details[:to], subject: '')
  end

end

__loading_end(__FILE__)

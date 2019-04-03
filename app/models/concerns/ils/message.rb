# app/models/concerns/ils/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# The base class for inbound messages from the ILS.
#
# Ils::Message instances must be created with data; if it is nil, :error option
# will be set and the derived class should modify its initialization
# accordingly.
#
class Ils::Message < Ils::Record::Base

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, String] data
  # @param [Hash, nil]    opt
  #
  # @option options [Symbol] :format  If not provided, this will be determined
  #                                     heuristically from *data*.
  #
  # This method overrides:
  # @see Ils::Record::Base#initialize
  #
  def initialize(data, **opt)
    start_time = Time.now
    opt = opt.dup
    opt[:format] ||= self.format_of(data)
    opt[:error]  ||= true if opt[:format].blank?
    data = wrap_outer(data, opt) if (opt[:format] == :xml) && !opt[:error]
    super(data, opt)
=begin # TODO: ???
  rescue Ils::RecvError => e
    Rails.logger.error { "#{self.class.name}: #{e}" }
    raise e
  rescue => e
    Rails.logger.error { "#{self.class.name}: invalid input: #{e}" }
    raise Ils::ParseError, e
=end
  ensure
    elapsed_time = '%g msec.' % (Time.now - start_time).in_milliseconds
    $stderr.puts ">>> #{self.class} processed in #{elapsed_time}"
    Rails.logger.info { "#{self.class} processed in #{elapsed_time}"}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # wrap_outer
  #
  # @param [String, Hash] data
  # @param [Hash, nil]    opt
  #
  # @return [String, Hash]
  #
  def wrap_outer(data, **opt)
    name = self.class.name.demodulize.camelcase(:lower)
    if data.is_a?(Hash)
      { name => data }
    elsif opt[:format] == :json
      %Q("#{name}":{#{data}})
    elsif data.start_with?('<?')
      data.sub(/^<\?.*?\?>/, '\0' + "<#{name}>") + "</#{name}>"
    else # opt[:format] == :xml
      "<#{name}>#{data}</#{name}>"
    end
  end

end

__loading_end(__FILE__)

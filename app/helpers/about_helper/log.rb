# app/helpers/about_helper/log.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AboutHelper::Log
#
# @see AboutHelper
#
module AboutHelper::Log

  include AboutHelper::Common

  def self.included(base)
    __included(base, '[AboutHelper::Log]')
  end

  DEFAULT_LOG_LINES = 1000

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The relative path to the log file.
  #
  # @param [String, Symbol, TrueClass, nil] env   Default: `Rails.env`.
  #
  # @return [String]
  #
  def log_path(env = nil)
    env = Rails.env if env.blank? || env.is_a?(TrueClass)
    "log/#{env}.log"
  end

  # default_log_lines
  #
  # @param [Hash, nil] opt
  #
  # @return [Numeric]
  #
  def default_log_lines(opt = nil)
    opt ||= defined?(params) ? params : {}
    count = opt[:lines].to_i
    count.zero? ? DEFAULT_LOG_LINES : count
  end

  # get_file_lines
  #
  # If :tail is not given then all lines of the file are returned.  If :tail
  # and :log are given then the final lines of the log file associated with the
  # route that initiated the display are not included in the result.
  #
  # @param [String, Boolean] log
  # @param [String]          path
  # @param [Numeric]         tail
  # @param [Numeric]         first
  # @param [Numeric]         last
  #
  # @return [Array<String>]
  #
  def get_file_lines(log: nil, path: nil, tail: nil, first: nil, last: nil)

    # Validate arguments.
    error =
      if path && log
        ':path and :log are mutually exclusive'
      elsif !(path || log)
        'either :path or :log must be given'
      elsif tail && (first || last)
        ':tail and :first/:last are mutually exclusive'
      elsif (arg = tail)  && (tail = tail.to_i).zero?
        "tail: #{arg.inspect} is invalid"
      elsif (arg = first) && (first = first.to_i).zero?
        "first: #{arg.inspect} is invalid"
      elsif (arg = last) && (last = last.to_i).zero?
        "last: #{arg.inspect} is invalid"
      end
    raise "#{__method__}: #{error}" if error

    # Set file path.
    path = log_path(log) if log

    # Get shell command to run or read the file directly.
    command =
      if tail
        "tail -#{tail} '#{path}'"
      elsif first && last
        first, last = [last, first] if first > last
        "sed -n '#{first},#{last}p' '#{path}'"
      elsif first
        "sed '1,#{first - 1}d' '#{path}'"
      elsif last
        "sed '#{last + 1}d' '#{path}'"
      end
    command ? get_output(command) : File.readlines(path)
  end

  # Get the output from a shell command.
  #
  # @param [String] command
  #
  # @return [Array<String>]
  #
  def get_output(command)
    open("|#{command}") { |f| f.readlines.map(&:rstrip) }
  end

  # Truncate the log file to zero bytes.
  #
  # @param [String, Symbol, TrueClass, nil] env   Default: `Rails.env`.
  #
  # @return [String]
  #
  def wipe_log(env = nil)
    path = log_path(env)
    get_output("> #{path}")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  ANSI_PREFIX   = "\u001b" + '\['
  ANSI_CODE     = '\d+[;\d]*[a-zA-Z]'
  ANSI_SEQUENCE = ANSI_PREFIX + ANSI_CODE

  # This method removes ANSI control sequences.
  #
  # @param [String, Array<String>] lines
  # @param [Boolean, String]       join   If not *false* the result is a string
  #                                         with lines joined by *join* if it
  #                                         is a string or "\n" if *join* is
  #                                         *true*.
  #
  # @return [String]                  If *lines* is a string and/or *join* is
  #                                     valid.
  # @return [Array<String>]           If *lines* is an array.
  #
  # == Usage Notes
  # The resultant string(s) are not HTML-safe.
  #
  def decolorize_lines(lines, join: nil)
    array = lines.is_a?(Array)
    lines =
      Array.wrap(lines).map do |line|
        line.gsub(/#{ANSI_PREFIX}#{ANSI_CODE}/u, '')
      end
    if join
      join = "\n" if join.is_a?(TrueClass)
      lines.join(join)
    elsif array
      lines
    else
      lines.first
    end
  end

  # This method identifies areas of the supplied text between ANSI control
  # sequences and wraps those areas in <span> tags with class(es) that map on
  # to the sequence(s).
  #
  # @param [String, Array<String>] lines
  # @param [Boolean]               log
  # @param [Boolean, String]       join   If not *false* the result is a string
  #                                         with lines joined by *join* if it
  #                                         is a string or "\n" if *join* is
  #                                         *true*.
  #
  # @return [ActiveSupport::SafeBuffer]         If *lines* is a string.
  # @return [Array<ActiveSupport::SafeBuffer>]  If *lines* is an array.
  #
  # @see app/assets/stylesheets/feature/_log
  #
  def colorize_lines(lines, log: nil, join: nil)

    array = lines.is_a?(Array)

    # Normalize the lines as a string with adjacent ANSI sequences collapsed so
    # that each ANSI prefix in the result indicates the start of one or more
    # visual changes to the following text.
    content =
      Array.wrap(lines)
        .map { |li| ERB::Util.h(li.to_s) }
        .join("\n")
        .gsub(/(#{ANSI_PREFIX}#{ANSI_CODE}){2,}/u) do |sequences|
        ANSI_PREFIX.tr('\\', '') + sequences.gsub(/#{ANSI_PREFIX}/u, '')
      end

    # Break the string into parts that start with one or more ANSI code(s),
    # wrap the parts in elements with CSS class(es) associated with the codes,
    # and reconstitute the array of lines.  (A part that has only '0m' at its
    # start represents the "normal" text that follows a highlighted part.)
    lines =
      content.split(/#{ANSI_PREFIX}/u).map { |part|
        part = part.sub(/^0m/, '')
        classes = []
        while part.sub!(/^(#{ANSI_CODE})/, '') do
          code = $1.to_s
          classes << ('c' + code.tr(';', '_')) if code.end_with?('m')
        end
        part = highlight(part, classes) if classes.present?
        part
      }.join.split("\n")

    # If the source is a log file, highlight selected important lines.
    if log
      lines.map! do |line|
        classes, tab =
          if line =~ /(^| )Started (GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)/
            ['log-highlight', true]
          end
        classes ||=
          case line
            when /(^| )Completed 2\d\d/    then 'log-success'
            when /(^| )Completed [^2]\d\d/ then 'log-error'
            when /::[a-zA-Z]*Error/        then 'log-error'
          end
        line = highlight(line, classes, tab: tab) if classes.present?
        line
      end
    end

    # Return with the content as display-ready string(s).
    if join
      join = '<br/>'.html_safe if join.is_a?(TrueClass)
      lines.join(ERB::Util.h(join)).html_safe
    elsif array
      lines.map(&:html_safe)
    else
      lines.first.html_safe
    end
  end

  # Highlight a section.
  #
  # The text is wrapped in a <span>; if :tab is *true* then the element is
  # given tabindex="0" so that you can tab between sections.
  #
  # @param [String]                     text
  # @param [String, Array<String>, nil] classes
  # @param [Boolean]                    tab       Allow tabbing to this section
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def highlight(text, classes = nil, tab: false)
    opt = {}
    opt[:class]    = Array.wrap(classes).join(' ') if classes.present?
    opt[:tabindex] = 0 if tab
    content_tag(:span, text.html_safe, opt)
  end

end

__loading_end(__FILE__)

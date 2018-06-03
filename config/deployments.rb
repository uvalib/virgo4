# config/deployments.rb
#
# frozen_string_literal: true
# warn_indent:           true

# =============================================================================
# Virgo deployments
# =============================================================================

# We use Rails environments prefixed with "search_" to specify behaviors and
# setting for the deployed application versus the behaviors and settings of the
# usual "production", "development", and "test" environments, which are
# implicitly reserved for non-deployed settings like desktop development.
#
# Unfortunately, this scheme could be problematic with any part of the Rails
# toolchain that is sensitive to Rails environment since "search_production"
# will not be treated the same as "production" for purposes of optimization,
# etc.
#
# As a transition, these methods are defined to be used in place of tests for
# `Rails.env` so that both the deployment setting and execution environment can
# be specified by one term.
#
# Ultimately this should be replaced with a different way of handling
# "config/environments" so that it contains only "production.rb",
# "development.rb" and "test.rb" with internal adjustments for any cases where
# values for the deployed setting is different than for the desktop setting.
#
module Deployments

  # Indicates that this Virgo instance is being run in a deployed setting,
  # regardless of the execution environment.
  #
  def deployed?
    @deployed ||= ENV['HOST'].to_s.downcase.end_with?('.lib.virginia.edu')
  end

  # Indicates that this Virgo instance is the deployed production
  # application.  (Currently equivalent to `Rails.env.search_production?`.)
  #
  def deployed_production?
    deployed? && production?
  end

  # Indicates that this Virgo instance is the deployed development
  # application.  (Currently equivalent to `Rails.env.search_development?`.)
  #
  def deployed_development?
    deployed? && development?
  end

  # Indicates that this Virgo instance is for automated testing in the
  # deployed setting.  (Currently  equivalent to`Rails.env.search_test?`.)
  #
  def deployed_test?
    deployed? && test?
  end

  # Indicates that this Virgo instance is being run on the desktop (or other
  # non-deployed setting), regardless of the execution environment.
  #
  def desktop?
    !deployed?
  end

  # Indicates that this Virgo instance is running in a non-deployed setting
  # in the "production" Rails environment.
  #
  def desktop_production?
    desktop? && production?
  end

  # Indicates that this Virgo instance is running in a non-deployed setting
  # in the "development" Rails environment.
  #
  def desktop_development?
    desktop? && development?
  end

  # Indicates that this Virgo instance is running in a non-deployed setting
  # in the "test" Rails environment.
  #
  def desktop_test?
    desktop? && test?
  end

  # Indicates whether this Virgo instance should exhibit behaviors of a
  # "production" system.
  #
  def production?
    deployment?(%w(production prod))
  end

  # Indicates whether this Virgo instance should exhibit behaviors of a
  # "development" system.
  #
  def development?
    deployment?(%w(development dev))
  end

  # Indicates whether this Virgo instance should exhibit behaviors of a
  # "test" system.
  #
  def test?
    deployment?('test')
  end

  # Indicates whether this Virgo instance has any of the given name suffixes.
  #
  # @param [Array<String>, String] suffix
  #
  def deployment?(*suffix)
    env = Rails.env.to_s
    suffix.flatten.any? { |s| env.end_with?(s) }
  end

end

# config/application.rb
#
# frozen_string_literal: true
# warn_indent:           true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative 'deployments'

module Virgo

  extend ::Deployments

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Specify I18n load paths.  @see config/locales/virgo/en.yml
    config.i18n.load_path +=
      Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    # Permitted parameters.
    # NOTE: Needs work.
    config.action_controller.permit_all_parameters = true # TODO: testing
    config.action_controller.action_on_unpermitted_parameters = :log
    config.action_controller.always_permitted_parameters = [
      # Rails
      'controller',
      'action',
      # Simple search
      'q',
      'f',
      'f[format][]',
      # Advanced search
      'f_inclusive',
      'f_inclusive[format][]',
      # Other
      'sort',
      'per_page',
    ]

    # Settings in config/environments/* take precedence over those specified
    # here. Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end

end

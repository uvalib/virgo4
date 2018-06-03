# config/application.rb

require_relative 'boot'

require 'rails/all'

# Pre-load the gems listed in Gemfile, including any gems limited to :test,
# :development, or :production.
Bundler.require(*Rails.groups)

require_relative 'deployments'

module Virgo

  extend ::Deployments

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    rails_version = Gem.latest_version_for('rails').to_s.presence
    rails_version &&= rails_version.sub(/(\d+\.\d+).*$/, '\1')
    config.load_defaults(rails_version || '5.2')

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

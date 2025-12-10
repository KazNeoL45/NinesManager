require_relative "boot"

require "rails/all"
Bundler.require(*Rails.groups)

module NinesManager
  class Application < Rails::Application
    config.autoload_lib(ignore: %w(assets tasks))
  end
end
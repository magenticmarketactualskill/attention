begin
  require "rails"

  module Attention
    class Engine < ::Rails::Engine
      isolate_namespace Attention

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: 'spec/factories'
      end

      rake_tasks do
        load "tasks/attention.rake"
      end
    end
  end
rescue LoadError
  # Rails not available - running in standalone mode
  module Attention
    class Engine
      # Stub for standalone usage
    end
  end
end

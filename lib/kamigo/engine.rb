require "rails/engine"
module Kamigo
  class Engine < ::Rails::Engine
    isolate_namespace Kamigo
  end
end

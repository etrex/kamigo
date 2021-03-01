# frozen_string_literal: true

require 'rails/generators/base'

module Kamigo
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a Kamigo initializer and copy locale files to your application."

      def copy_initializer
        template "kamigo.rb", "config/initializers/kamigo.rb"
      end
    end
  end
end
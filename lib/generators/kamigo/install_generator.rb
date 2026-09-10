require "rails/generators/base"
module Kamigo
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __dir__)
      desc "Install Kamigo 1.0 identity/delivery migrations and configuration guidance."
      def install
        template "kamigo.rb", "config/initializers/kamigo.rb"
        directory = File.expand_path("../../..", __dir__)
        Dir[File.join(directory, "db/migrate/*.rb")].sort.each do |source|
          copy_file source, "db/migrate/#{File.basename(source)}"
        end
      end
    end
  end
end

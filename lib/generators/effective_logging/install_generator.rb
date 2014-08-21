module EffectiveLogging
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      desc "Creates an EffectiveLogging initializer in your application."

      source_root File.expand_path("../../templates", __FILE__)

      def self.next_migration_number(dirname)
        if not ActiveRecord::Base.timestamped_migrations
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def copy_initializer
        template "effective_logging.rb", "config/initializers/effective_logging.rb"
      end

      def create_migration_file
        @logs_table_name = ':' + EffectiveLogging.logs_table_name.to_s

        migration_template '../../../db/migrate/01_create_effective_logging.rb.erb', 'db/migrate/create_effective_logging.rb'
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end

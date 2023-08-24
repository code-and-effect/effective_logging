module Effective
  class Log < ActiveRecord::Base
    self.table_name = (EffectiveLogging.logs_table_name || :logs).to_s

    effective_logging_log
  end
end

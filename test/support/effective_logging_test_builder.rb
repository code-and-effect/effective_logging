module EffectiveLoggingTestBuilder

  def build_effective_log
    Effective::Log.new(status: 'info', message: 'message')
  end

end

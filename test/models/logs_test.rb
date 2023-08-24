require 'test_helper'

class LogsTest < ActiveSupport::TestCase
  test 'is valid' do
    log = build_effective_log()
    assert log.valid?
  end

  test 'with the logger' do
    log = EffectiveLogger.log('message', 'info', {})
    assert log.valid?

    log = EffectiveLogger.info('message', {})
    assert_equal 'info', log.status
    assert log.valid?

    log = EffectiveLogger.success('message', {})
    assert_equal 'success', log.status
    assert log.valid?
  end
end

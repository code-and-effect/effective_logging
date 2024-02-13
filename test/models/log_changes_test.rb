require 'test_helper'

class LogChangesTest < ActiveSupport::TestCase
  test 'logs create action' do
    user = User.new(email: 'someone@something.com', first_name: 'First', last_name: 'Last', password: 'Password123!')

    assert_equal 0, user.logged_changes.count
    user.save!

    # Create
    assert_equal 1, user.logged_changes.count
    assert_equal 'Created', user.logged_changes.last.message

    # Update
    user.update!(first_name: 'New First Name')
    assert_equal 2, user.logged_changes.count
    assert_equal "Updated\nFirst Name: First &rarr; New First Name", user.logged_changes.last.message

    # Destroy
    user.destroy!
    assert_equal 3, user.logged_changes.count
    assert_equal "Deleted", user.logged_changes.last.message
  end

  test 'when log_changes? suppressed' do
    user = User.new(email: 'someone@something.com', first_name: 'First', last_name: 'Last', password: 'Password123!')

    # setting last_name == 'Skip Log Changes' disables the log changes
    assert_equal 0, user.logged_changes.count
    user.update!(last_name: 'Skip Log Changes')

    # No Create logging
    assert_equal 0, user.logged_changes.count

    # No Update logging
    user.update!(first_name: 'New First Name')
    assert_equal 0, user.logged_changes.count

    # No Destroy logging
    user.destroy!
    assert_equal 0, user.logged_changes.count
  end

end

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  log_changes

  # effective_logging_organization_user
  # effective_logging_user

  def to_s
    "#{first_name} #{last_name}"
  end

  def log_changes?
    return false if last_name == 'Skip Log Changes'
    true
  end

end

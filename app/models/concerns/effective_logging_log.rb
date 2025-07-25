# frozen_string_literal: true

# EffectiveLoggingLog
#
# Mark your log model with effective_logging_log to get all the includes

module EffectiveLoggingLog
  extend ActiveSupport::Concern

  module Base
    def effective_logging_log
      include ::EffectiveLoggingLog
    end
  end

  module ClassMethods
    def effective_logging_log?; true; end
  end

  included do
    self.table_name = (EffectiveLogging.logs_table_name || :logs).to_s

    belongs_to :user, polymorphic: true, optional: true
    belongs_to :changes_to, polymorphic: true, optional: true # This is the log_changes to: option
    belongs_to :associated, polymorphic: true, optional: true

    effective_resource do
      status              :string

      changes_to_type     :string
      changes_to_id       :string

      associated_type     :string
      associated_id       :integer
      associated_to_s     :string

      message             :text
      details             :text

      timestamps
    end

    if EffectiveResources.serialize_with_coder?
      serialize :details, type: Hash, coder: YAML
    else
      serialize :details, Hash
    end

    validates :message, presence: true
    validates :status, presence: true

    validate(if: -> { status.present? }) do
      errors.add(:status, "is not included") unless EffectiveLogging.statuses.include?(status)
    end

    scope :deep, -> { includes(:user) }
    scope :sorted, -> { order(:id) }
    scope :logged_changes, -> { where(status: EffectiveLogging.log_changes_status) }
    scope :changes, -> { where(status: EffectiveLogging.log_changes_status) }

    # Dynamically add logging methods based on the defined statuses
    # EffectiveLogging.info 'my message'
    (EffectiveLogging.statuses || []).each do |status|
      send(:define_method, status) { |message, options={}| log(message, status, options) }
    end

  end

  # Instance Methods
  def to_s
    "#{model_name.human} ##{id}"
  end

  def associated_to_s=(value)
    super(value.to_s[0...255].presence) # Take only first 255 characters
  end

  def log(message, status = nil, options = {})
    status ||= EffectiveLogging.statuses.first
    EffectiveLogger.log(message, status, options)
  end

  def details
    Hash(self[:details])
  end

  def next_log
    self.class.order(id: :asc).where('id > ?', id).first
  end

  def prev_log
    self.class.order(id: :desc).where('id < ?', id).first
  end

end

# frozen_string_literal: true

module Effective
  class Log < ActiveRecord::Base
    self.table_name = EffectiveLogging.logs_table_name.to_s

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

    serialize :details, Hash

    validates :message, presence: true
    validates :status, presence: true, inclusion: { in: EffectiveLogging.statuses }

    scope :deep, -> { includes(:user, :associated) }
    scope :sorted, -> { order(:id) }
    scope :logged_changes, -> { where(status: EffectiveLogging.log_changes_status) }
    scope :changes, -> { where(status: EffectiveLogging.log_changes_status) }

    def to_s
      "Log #{id}"
    end

    def associated_to_s=(value)
      super(value.to_s[0...255].presence) # Take only first 255 characters
    end

    def log(message, status = EffectiveLogging.statuses.first, options = {})
      EffectiveLogger.log(message, status, options)
    end

    def details
      self[:details] || {}
    end

    def next_log
      Log.order(id: :asc).where('id > ?', id).first
    end

    def prev_log
      Log.order(id: :desc).where('id < ?', id).first
    end

    # Dynamically add logging methods based on the defined statuses
    # EffectiveLogging.info 'my message'
    (EffectiveLogging.statuses || []).each do |status|
      send(:define_method, status) { |message, options={}| log(message, status, options) }
    end

  end
end

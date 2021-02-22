module Effective
  class Log < ActiveRecord::Base
    self.table_name = EffectiveLogging.logs_table_name.to_s

    # Self-Referencing relationship
    belongs_to :parent, class_name: 'Effective::Log', counter_cache: true, optional: true
    has_many :logs, class_name: 'Effective::Log', foreign_key: :parent_id

    belongs_to :user, polymorphic: true, optional: true
    belongs_to :changes_to, polymorphic: true, optional: true # This is the log_changes to: option
    belongs_to :associated, polymorphic: true, optional: true

    effective_resource do
      logs_count          :integer  # Rails Counter Cache

      changes_to_type     :string
      changes_to_id       :string

      associated_type     :string
      associated_id       :integer
      associated_to_s     :string

      status              :string
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
      EffectiveLogger.log(message, status, (options || {}).merge(parent: self))
    end

    def details
      self[:details] || {}
    end

    def next_log
      Log.order(id: :asc).where(parent_id: parent_id).where('id > ?', id).first
    end

    def prev_log
      Log.order(id: :desc).where(parent_id: parent_id).where('id < ?', id).first
    end

    def child_logs_datatable
      EffectiveLogsDatatable.new(log_id: id)
    end

    # Dynamically add logging methods based on the defined statuses
    # EffectiveLogging.info 'my message'
    (EffectiveLogging.statuses || []).each do |status|
      send(:define_method, status) { |message, options={}| log(message, status, options) }
    end

  end
end

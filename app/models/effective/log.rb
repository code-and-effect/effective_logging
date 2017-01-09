module Effective
  class Log < ActiveRecord::Base
    self.table_name = EffectiveLogging.logs_table_name.to_s

    # These 3 attr_accessors are set on the controller #show actions
    attr_accessor :datatable
    attr_accessor :next_log
    attr_accessor :prev_log

    # Self-Referencing relationship
    belongs_to :parent, class_name: 'Effective::Log', counter_cache: true
    has_many :logs, class_name: 'Effective::Log', foreign_key: :parent_id

    # The user this log item is referring to
    # An associated object, if we wanna add anything extra
    belongs_to :user, optional: true
    belongs_to :associated, polymorphic: true, optional: true

    serialize :details, Hash

    # Attributes
    # logs_count          :integer  # Rails Counter Cache

    # associated_type     :string
    # associated_id       :integer
    # associated_to_s     :string
    # message             :string
    # details             :text
    # status              :string
    # timestamps

    validates :message, presence: true
    validates :status, presence: true, inclusion: { in: EffectiveLogging.statuses }

    default_scope -> { order(updated_at: :desc) }

    scope :logged_changes, -> { where(status: EffectiveLogging.log_changes_status)}
    scope :changes, -> { where(status: EffectiveLogging.log_changes_status)}

    def to_s
      "Log #{id}"
    end

    def log(message, status = EffectiveLogging.statuses.first, options = {})
      EffectiveLogger.log(message, status, (options || {}).merge(parent: self))
    end

    def details
      self[:details] || {}
    end

    # def next_log
    #   @next_log ||= Log.unscoped.order(:id).where(:parent_id => self.parent_id).where('id > ?', self.id).first
    # end

    # def prev_log
    #   @prev_log ||= Log.unscoped.order(:id).where(:parent_id => self.parent_id).where('id < ?', self.id).last
    # end

    # Dynamically add logging methods based on the defined statuses
    # EffectiveLogging.info 'my message'
    (EffectiveLogging.statuses || []).each do |status|
      send(:define_method, status) { |message, options={}| log(message, status, options) }
    end

  end
end



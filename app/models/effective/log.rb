module Effective
  class Log < ActiveRecord::Base
    self.table_name = EffectiveLogging.logs_table_name.to_s

    # Self-Referencing relationship
    belongs_to :parent, :class_name => 'Effective::Log', :counter_cache => true
    has_many :logs, :dependent => :destroy, :class_name => 'Effective::Log', :foreign_key => :parent_id

    # The user this log item is referring to
    # An associated object, if we wanna add anything extra
    belongs_to :user
    belongs_to :associated, :polymorphic => true

    serialize :details, Hash

    structure do
      logs_count          :integer  # Rails Counter Cache

      message             :string, :validates => [:presence]
      details             :text

      status              :string, :validates => [:presence, :inclusion => {:in => EffectiveLogging.statuses }]

      timestamps
    end

    default_scope -> { order("#{EffectiveLogging.logs_table_name.to_s}.updated_at DESC") }

    def log(message, status = EffectiveLogging.statuses.first, options = {})
      EffectiveLogger.log(message, status, (options || {}).merge({:parent => self}))
    end

    def details
      self[:details] ||= {}
    end

    def next_log
      @next_log ||= Log.unscoped.order(:id).where(:parent_id => self.parent_id).where('id > ?', self.id).first
    end

    def prev_log
      @prev_log ||= Log.unscoped.order(:id).where(:parent_id => self.parent_id).where('id < ?', self.id).last
    end

    # Dynamically add logging methods based on the defined statuses
    # EffectiveLogging.info 'my message'
    (EffectiveLogging.statuses || []).each do |status|
      send(:define_method, status) { |message, options={}| log(message, status, options) }
    end

  end
end



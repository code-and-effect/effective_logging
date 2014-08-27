# Call EffectiveLog.info or EffectiveLog.success  EffectiveLog.error

class EffectiveLogger
  def self.log(message, status = EffectiveLogging.statuses.first, options = {})
    if options[:user].present? && !options[:user].kind_of?(User)
      raise ArgumentError.new("Log.log :user => ... argument must be a User object")
    end

    if options[:parent].present? && !options[:parent].kind_of?(Effective::Log)
      raise ArgumentError.new("Log.log :parent => ... argument must be an Effective::Log object")
    end

    if options[:associated].present? && !options[:associated].kind_of?(ActiveRecord::Base)
      raise ArgumentError.new("Log.log :associated => ... argument must be an ActiveRecord::Base object")
    end

    Effective::Log.new().tap do |log|
      log.message = message
      log.status = status

      log.user_id = options.delete(:user_id).to_i if options[:user_id]
      log.user = options.delete(:user) if options[:user]

      log.parent = options.delete(:parent)
      log.associated = options.delete(:associated)

      log.details = options if options.kind_of?(Hash)

      log.save
    end
  end

  # Dynamically add logging methods based on the defined statuses
  # EffectiveLogging.info 'my message'
  (EffectiveLogging.statuses || []).each do |status|
    self.singleton_class.send(:define_method, status) { |message, options={}| log(message, status, options) }
  end

end

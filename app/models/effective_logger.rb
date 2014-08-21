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

    @last = Effective::Log.new().tap do |log|
      log.message = message
      log.status = status

      if options[:user].present?
        log.user = options[:user]
      elsif options[:user_id].present?
        log.user_id = options[:user_id]
      end

      log.details = options[:details].try(:to_s)
      log.associated = options[:associated]
      log.parent = options[:parent]

      log.save!
    end
  end

  def self.last
    @last
  end

end

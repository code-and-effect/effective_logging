# Call EffectiveLog.info or EffectiveLog.success  EffectiveLog.error

class EffectiveLogger
  def self.log(message, status = EffectiveLogging.statuses.first, options = {})
    return if EffectiveLogging.supressed?

    options = Hash(options).delete_if { |k, v| v.blank? }

    if options[:user].present? && !options[:user].class.name.end_with?('User')
      raise ArgumentError.new('Log.log :user => ... argument must be a User object')
    end

    if options[:parent].present? && !options[:parent].kind_of?(Effective::Log)
      raise ArgumentError.new('Log.log :parent => ... argument must be an Effective::Log object')
    end

    if options[:associated].present? && !options[:associated].kind_of?(ActiveRecord::Base)
      raise ArgumentError.new('Log.log :associated => ... argument must be an ActiveRecord::Base object')
    end

    if options[:request].present? && options[:request].respond_to?(:referrer)
      request = options.delete(:request)

      options[:ip] ||= request.ip
      options[:referrer] ||= request.referrer
      options[:user_agent] ||= request.user_agent
    end

    log = Effective::Log.new(
      message: message,
      status: status,
      user_id: options.delete(:user_id),
      user_type: options.delete(:user_type),
      user: options.delete(:user),
      parent: options.delete(:parent),
      associated: options.delete(:associated),
      associated_to_s: options.delete(:associated_to_s),
      details: options
    )

    if log.associated.present?
      log.associated_to_s ||= log.associated.to_s
    end

    log.save!

    log
  end

  # Dynamically add logging methods based on the defined statuses
  # EffectiveLogging.info 'my message'
  (EffectiveLogging.statuses || []).each do |status|
    self.singleton_class.send(:define_method, status) { |message, options={}| log(message, status, options) }
  end

end

module ActsAsTrashable
  extend ActiveSupport::Concern

  module ActiveRecord
    def acts_as_trashable(*options)
      @acts_as_trashable_options = options.try(:first) || {}

      unless @acts_as_trashable_options.kind_of?(Hash)
        raise ArgumentError.new("invalid arguments passed to (effective_trash) acts_as_trashable. Expecting no options.")
      end

      include ::ActsAsTrashable
    end
  end

  included do
    has_one :trash, -> { where(status: EffectiveLogging.trashable_status) }, as: :associated, class_name: Effective::Log

    before_destroy do
      EffectiveLogging::ActiveRecordLogger.new(self, acts_as_trashable_options).trashed!
      true
    end

    # Parse Options
    acts_as_trashable_options = {
      only: Array(@acts_as_trashable_options[:only]).map { |attribute| attribute.to_s },
      except: Array(@acts_as_trashable_options[:except]) + ['trash'].map { |attribute| attribute.to_s },
      additionally: Array(@acts_as_trashable_options[:additionally]).map { |attribute| attribute.to_s }
    }

    self.send(:define_method, :acts_as_trashable_options) { acts_as_trashable_options }
  end

  module ClassMethods
  end

  # Regular instance methods

end


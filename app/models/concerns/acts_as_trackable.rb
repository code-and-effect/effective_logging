# frozen_string_literal: true

# Just works with effective_resources controller to track views on show action
# Add acts_as_trackable to your model
# add_column :things, :tracks_count, :integer, default: 0
module ActsAsTrackable
  extend ActiveSupport::Concern

  module Base
    def acts_as_trackable(*options)
      @acts_as_trackable = options || []
      include ::ActsAsTrackable
    end
  end

  included do
    has_many :tracks, -> { order(:id) }, as: :owner, class_name: 'Effective::Track'
  end

  module ClassMethods
    def acts_as_trackable?; true; end
  end

  # Instance Methods
  def track!(action: 'view', user: nil, details: nil)
    tracks.create!(action: action, user: user, details: details)
  end
end

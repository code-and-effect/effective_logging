# frozen_string_literal: true
module Effective
  class Track < ActiveRecord::Base
    self.table_name = (EffectiveLogging.tracks_table_name || :tracks).to_s

    # The owner resource of this tracked thing
    belongs_to :owner, polymorphic: true, counter_cache: true

    # Present when the user is signed in
    belongs_to :user, polymorphic: true, optional: true

    ACTIONS = ['view', 'click']

    effective_resource do
      action          :string

      title           :string
      details         :text

      timestamps
    end

    if EffectiveResources.serialize_with_coder?
      serialize :details, type: Hash, coder: YAML
    else
      serialize :details, Hash
    end

    validates :action, presence: true
    before_save :assign_title # Assign computed title always

    scope :sorted, -> { order(:id) }
    scope :deep, -> { includes(:owner, :user) }

    scope :signed_in, -> { where.not(user_id: nil) }
    scope :signed_out, -> { where(user_id: nil) }

    def to_s
      title.presence || model_name.human
    end

    private

    def assign_title
      title = [action, 'of', "#{owner}", ("by #{user || 'guest user'}")].compact.join(' ')
      assign_attributes(title: title)
    end

  end
end

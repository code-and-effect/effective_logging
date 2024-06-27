module Admin
  class EffectiveTracksDatatable < Effective::Datatable
    filters do
      filter_date_range

      scope :all
      scope :signed_in
      scope :signed_out
    end

    datatable do
      col :id, visible: false

      col :created_at

      col :action
      col :owner, label: 'Resource'
      col :user

      col :title
      col :details, visible: false
    end

    collection do
      Effective::Track.deep.all.where(created_at: date_range)
    end

  end
end

class CreateEffectiveLogging < ActiveRecord::Migration[6.0]
  def change
    create_table :logs do |t|
      t.string        :status

      t.string        :user_type
      t.integer       :user_id

      t.string        :changes_to_type
      t.integer       :changes_to_id

      t.string        :associated_type
      t.integer       :associated_id
      t.string        :associated_to_s

      t.text          :message
      t.text          :details

      t.timestamps
    end

    add_index :logs, :id, order: { id: :desc }
    add_index :logs, :updated_at
    add_index :logs, :user_id
    add_index :logs, :status
    add_index :logs, :associated_to_s
    add_index :logs, [:associated_type, :associated_id]
    add_index :logs, [:changes_to_type, :changes_to_id]

    enable_extension('pg_trgm')
    add_index :logs, :message, using: :gin, opclass: :gin_trgm_ops
    add_index :logs, :details, using: :gin, opclass: :gin_trgm_ops
  end
end

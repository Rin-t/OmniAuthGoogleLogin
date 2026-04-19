class CreateOauthPendingStates < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_pending_states do |t|
      t.string :state, null: false
      t.string :redirect_uri, null: false
      t.datetime :expires_at, null: false
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :oauth_pending_states, :state, unique: true
    add_index :oauth_pending_states, :expires_at
  end
end

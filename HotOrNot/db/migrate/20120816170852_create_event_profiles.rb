class CreateEventProfiles < ActiveRecord::Migration
  def change
    create_table :event_profiles do |t|

      t.timestamps
    end
  end
end

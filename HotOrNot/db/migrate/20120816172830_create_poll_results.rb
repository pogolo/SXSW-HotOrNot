class CreatePollResults < ActiveRecord::Migration
  def change
    create_table :poll_results do |t|

      t.timestamps
    end
  end
end

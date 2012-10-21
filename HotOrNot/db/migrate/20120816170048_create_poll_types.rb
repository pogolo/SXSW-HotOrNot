class CreatePollTypes < ActiveRecord::Migration
  def change
    create_table :poll_types do |t|

      t.timestamps
    end
  end
end

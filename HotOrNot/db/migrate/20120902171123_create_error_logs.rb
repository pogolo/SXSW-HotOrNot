class CreateErrorLogs < ActiveRecord::Migration
  def change
    create_table :error_logs do |t|

      t.timestamps
    end
  end
end

class CreateImportEvents < ActiveRecord::Migration
  def change
    create_table :import_events do |t|

      t.timestamps
    end
  end
end

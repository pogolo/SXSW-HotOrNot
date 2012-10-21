class CreateImportTwitters < ActiveRecord::Migration
  def change
    create_table :import_twitters do |t|

      t.timestamps
    end
  end
end

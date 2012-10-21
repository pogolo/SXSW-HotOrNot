class CreateImportUsers < ActiveRecord::Migration
  def change
    create_table :import_users do |t|

      t.timestamps
    end
  end
end

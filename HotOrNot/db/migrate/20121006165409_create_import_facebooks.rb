class CreateImportFacebooks < ActiveRecord::Migration
  def change
    create_table :import_facebooks do |t|

      t.timestamps
    end
  end
end

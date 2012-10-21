class CreateIncrementTypes < ActiveRecord::Migration
  def change
    create_table :increment_types do |t|

      t.timestamps
    end
  end
end

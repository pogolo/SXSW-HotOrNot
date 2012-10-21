class CreateCompileTwitters < ActiveRecord::Migration
  def change
    create_table :compile_twitters do |t|

      t.timestamps
    end
  end
end

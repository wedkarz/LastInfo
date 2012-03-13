class CreateLoadData < ActiveRecord::Migration
  def change
    create_table :load_data do |t|

      t.timestamps
    end
  end
end

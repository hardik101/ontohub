class CreateOntologies < ActiveRecord::Migration
  def change
    create_table :ontologies do |t|
      t.references :logic
      t.string :uri, :null => false
      t.string :state, :default => 'pending', :null => false
      t.string :name
      t.text :description

      t.timestamps :null => false
    end

    change_table :ontologies do |t|
      t.index :logic_id
      t.foreign_key :logics
    end
  end
end

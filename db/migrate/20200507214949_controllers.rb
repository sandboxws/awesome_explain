class Controllers < ActiveRecord::Migration[ActiveRecord.version.to_s.to_f]
  def connection
    ActiveRecord::Base.establish_connection(AwesomeExplain::Config.instance.db_config).connection
  end

  def change
    create_table :controllers do |t|
      t.column :name, :string
      t.column :action, :string
      t.column :path, :string
      t.column :params, :string
      t.column :session_id, :string
      t.timestamps
    end
  end
end

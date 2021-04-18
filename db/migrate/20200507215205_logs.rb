class Logs < ActiveRecord::Migration[ActiveRecord.version.to_s.to_f]
  def connection
    ActiveRecord::Base.establish_connection(AwesomeExplain::Config.instance.db_config).connection
  end

  def change
    create_table :logs do |t|
      t.column :collection, :string
      t.column :source_name, :string
      t.column :operation, :string
      t.column :collscan, :integer
      t.column :command, :string
      t.column :duration, :double
      t.column :session_id, :string
      t.column :lsid, :string
      t.column :stacktrace_id, :integer
      t.column :explain_id, :integer
      t.column :controller_id, :integer
      t.timestamps
    end
  end
end

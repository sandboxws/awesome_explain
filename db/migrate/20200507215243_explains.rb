class Explains < ActiveRecord::Migration[ActiveRecord.version.to_s.to_f]
  def connection
    ActiveRecord::Base.establish_connection(AwesomeExplain::Config.instance.db_config).connection
  end

  def change
    create_table :explains do |t|
      t.column :collection, :string
      t.column :source_name, :string
      t.column :command, :string
      t.column :collscan, :integer
      t.column :winning_plan, :string
      t.column :winning_plan_raw, :string
      t.column :used_indexes, :string
      t.column :duration, :double
      t.column :documents_returned, :integer
      t.column :documents_examined, :integer
      t.column :keys_examined, :integer
      t.column :rejected_plans, :integer
      t.column :session_id, :string
      t.column :lsid, :string
      t.column :stacktrace_id, :integer
      t.column :controller_id, :integer
      t.timestamps
    end
  end
end

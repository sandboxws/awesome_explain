class Stacktraces < ActiveRecord::Migration[ActiveRecord.version.to_s.to_f]
  def connection
    ActiveRecord::Base.establish_connection(AwesomeExplain::Config.instance.db_config).connection
  end

  def change
    create_table :stacktraces do |t|
      t.column :stacktrace, :string
      t.timestamps
    end
  end
end

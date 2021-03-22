module AwesomeExplain
  module Stats
    class PostgreSQL
      def self.upsert!
        upsert_seq_scans!
        upsert_dml_stats!
      end

      def self.upsert_seq_scans!
        result = ActiveRecord::Base.connection.execute(seq_scans_sql).to_a
        result.each do |row|
          row = OpenStruct.new(row)
          pg_seq_scan = AwesomeExplain::PgSeqScan.find_or_create_by({
            schema_name: row.schema_name,
            table_name: row.table_name
          })

          pg_seq_scan.update({
            seq_scan: row.seq_scan,
            seq_tup_read: row.seq_tup_read,
            idx_scan: row.idx_scan,
            idx_tup_fetch: row.idx_tup_fetch,
            size_bytes: row.size_bytes
          })
        end
      end

      def self.upsert_dml_stats!
        result = ActiveRecord::Base.connection.execute(dml_stats_sql).to_a
        result.each do |row|
          row = OpenStruct.new(row)
          pg_dml_stat = AwesomeExplain::PgDmlStat.find_or_create_by({
            schema_name: row.schema_name,
            table_name: row.table_name
          })

          pg_dml_stat.update({
            total_inserts: row.n_tup_ins,
            total_updates: row.n_tup_upd,
            total_deletes: row.n_tup_del,
          })
        end
      end

      def self.seq_scans_sql
        "select schemaname as schema_name, relname as table_name, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, pg_relation_size(schemaname::text || '.'::text || relname::text) as size_bytes from pg_stat_user_tables"
      end

      def self.dml_stats_sql
        "SELECT schemaname as schema_name, relname as table_name, n_tup_ins, n_tup_upd, n_tup_del FROM pg_stat_user_tables"
      end
    end
  end
end

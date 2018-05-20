require_relative 'returning_attributes/accessor'
require_relative 'returning_attributes/version'
require_relative 'returning_attributes/with_returning'

require 'active_support/lazy_load_hooks'

module ActiveRecord
  module ReturningAttributes
    def self.monkey_patch_persistence!
      Persistence.module_eval do
        def _create_record(attribute_names = self.attribute_names)
          attribute_names &= self.class.column_names
          attributes_values = attributes_with_values_for_create(attribute_names)

          new_id, result = self.class.connection.with_returning(returning) do
            self.class._insert_record(attributes_values)
          end

          self.id ||= new_id if self.class.primary_key

          self.class.returning.each do |column|
            write_attribute(column, result.to_hash.first[column.to_s])
          end

          @new_record = false

          yield(self) if block_given?

          id
        end
      end
    end

    def self.monkey_patch_database_statements!
      ConnectionAdapters::DatabaseStatements.module_eval do
        def insert(arel, name = nil, pk = nil, id_value = nil, sequence_name = nil, binds = [])
          sql, binds = to_sql_and_binds(arel, binds)
          @_insert_result = exec_insert(sql, name, binds, pk, sequence_name)
          id_value || last_inserted_id(@_insert_result)
        end
      end
    end

    def self.monkey_patch_postgresql_database_statements!
      require 'active_record/connection_adapters/postgresql/database_statements'

      ConnectionAdapters::PostgreSQL::DatabaseStatements.module_eval do
        private

        def sql_for_insert(sql, pk, id_value, sequence_name, binds)
          if pk.nil?
            # Extract the table from the insert sql. Yuck.
            table_ref = extract_table_ref_from_insert_sql(sql)
            pk = primary_key(table_ref) if table_ref
          end

          if pk = suppress_composite_primary_key(pk)
            if @_returning
              sql = "#{sql} RETURNING #{[pk, @_returning].flatten.map { |column| quote_column_name(column) }.join(', ')}"
            else
              raise 'This case shouldn’t happen.'
            end
          end

          super
        end
      end
    end

    def self.extend_postgresql_adapter!
      require 'active_record/connection_adapters/postgresql_adapter'
      ConnectionAdapters::PostgreSQLAdapter.include(WithReturning)
    end

    ActiveSupport.on_load(:active_record) do
      include Accessor

      ReturningAttributes.monkey_patch_persistence!
      ReturningAttributes.monkey_patch_database_statements!
      ReturningAttributes.monkey_patch_postgresql_database_statements!
      ReturningAttributes.extend_postgresql_adapter!
    end
  end
end

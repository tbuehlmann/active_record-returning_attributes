require_relative '../returning_attributes/accessor'
require_relative '../returning_attributes/with_returning'

module ActiveRecord
  module ReturningAttributes
    module Patching
      def self.patch_base
        Base.include(Accessor)
      end

      def self.patch_persistence
        Persistence.module_eval do
          private

          def _create_record(attribute_names = self.attribute_names)
            attribute_names &= self.class.column_names
            attributes_values = attributes_with_values_for_create(attribute_names)

            new_id, returned_attributes = self.class.connection.with_returning_attributes(returning_attributes) do
              self.class._insert_record(attributes_values)
            end

            self.id ||= new_id if self.class.primary_key

            returning_attributes.each do |attribute|
              write_attribute(attribute, returned_attributes[attribute.to_s]) if returned_attributes.key?(attribute.to_s)
            end

            @new_record = false

            yield(self) if block_given?

            id
          end

          def _update_record(attribute_names = self.attribute_names)
            attribute_names &= self.class.column_names
            attribute_names = attributes_for_update(attribute_names)

            if attribute_names.empty?
              affected_rows = 0
              @_trigger_update_callback = true
            else
              affected_rows, returned_attributes = self.class.connection.with_returning_attributes(returning_attributes) do
                _update_row(attribute_names)
              end

              returning_attributes.each do |attribute|
                write_attribute(attribute, returned_attributes[attribute.to_s]) if returned_attributes.key?(attribute.to_s)
              end

              @_trigger_update_callback = affected_rows == 1
            end

            yield(self) if block_given?

            affected_rows
          end
        end
      end

      def self.patch_database_statements
        ConnectionAdapters::DatabaseStatements.module_eval do
          def exec_insert(sql, name = nil, binds = [], pk = nil, sequence_name = nil)
            sql, binds = sql_for_insert(sql, pk, nil, sequence_name, binds)

            exec_query(sql, name, binds).tap do |result|
              @_returned_attributes = result.first.to_hash
            end
          end

          def update(arel, name = nil, binds = [])
            sql, binds = to_sql_and_binds(arel, binds)

            if @_returning_attributes && !@_returning_attributes.empty?
              sql = "#{sql} RETURNING #{@_returning_attributes.map { |column| quote_column_name(column) }.join(', ')}"
            end

            exec_update(sql, name, binds)
          end
        end
      end

      def self.patch_postgresql_database_statements
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
              sql = "#{sql} RETURNING #{[pk, @_returning_attributes].flatten.map { |column| quote_column_name(column) }.join(', ')}"
            end

            super
          end
        end
      end

      def self.patch_postgresql_adapter
        require 'active_record/connection_adapters/postgresql_adapter'

        ConnectionAdapters::PostgreSQLAdapter.class_eval do
          include WithReturning

          private

          def execute_and_clear(sql, name, binds, prepare: false)
            if without_prepared_statement?(binds)
              result = exec_no_cache(sql, name, [])
            elsif !prepare
              result = exec_no_cache(sql, name, binds)
            else
              result = exec_cache(sql, name, binds)
            end

            if @_returning_attributes && !@_returning_attributes.empty?
              @_returned_attributes = result.to_a.first
            end

            ret = yield result
            result.clear
            ret
          end
        end
      end
    end
  end
end

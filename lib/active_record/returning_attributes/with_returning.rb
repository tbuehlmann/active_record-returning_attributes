module ActiveRecord
  module ReturningAttributes
  	module WithReturning
      def with_returning(returning)
        begin
          @_returning = returning
          [yield, @_insert_result]
        ensure
          @_returning = nil
          @_insert_result = nil
        end
      end
    end
  end
end

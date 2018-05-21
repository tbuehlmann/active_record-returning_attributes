module ActiveRecord
  module ReturningAttributes
    module WithReturning
      def with_returning_attributes(attributes)
        begin
          @_returning_attributes = attributes
          [yield, @_returned_attributes || {}]
        ensure
          @_returning_attributes = nil
          @_returned_attributes = nil
        end
      end
    end
  end
end

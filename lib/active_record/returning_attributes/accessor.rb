require 'active_support/concern'

module ActiveRecord
  module ReturningAttributes
    module Accessor
      extend ActiveSupport::Concern

      def returning_attributes
        self.class.returning_attributes
      end

      module ClassMethods
        attr_reader :returning_attributes

        def returning_attributes=(attributes)
          @returning_attributes = attributes.map(&:to_s)
        end
      end
    end
  end
end

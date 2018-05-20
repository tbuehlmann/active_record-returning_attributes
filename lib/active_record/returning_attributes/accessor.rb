require 'active_support/concern'

module ActiveRecord
  module ReturningAttributes
  	module Accessor
      extend ActiveSupport::Concern

      included do
        class_attribute :returning, default: []
      end
    end
  end
end

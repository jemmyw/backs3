require 'active_support/core_ext'

module Backs3
  module Storage
    extend ActiveSupport::Dependencies

    class Base
      def initialize(options = {})
        @options = (options || {}).symbolize_keys
        validate_options
      end

      def method_missing(symbol, *args)
        if %w(store read delete exists? list).include?(symbol.to_s)
          raise "Not implemented"
        else
          super
        end
      end
      
      protected

      def validate_options

      end
    end
  end
end
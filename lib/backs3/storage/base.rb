require 'active_support/core_ext'

module Backs3
  module Storage
    extend ActiveSupport::Dependencies

    class Base
      def initialize(options = {})
        @options = (options || {}).stringify_keys
        validate_options
      end

      def store(name, value)
        raise "Not implemented"
      end

      def read(name)
        raise "Not implemented"
      end

      def delete(name)
        raise "Not implemented"
      end

      def exists?(name)
        raise "Not implemented"
      end

      def list(path = nil)
        raise "Not implemented"
      end

      protected

      def validate_options

      end
    end
  end
end
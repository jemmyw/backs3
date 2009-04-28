module Backs3
  module Storage
    class Aws < Backs3::Storage::Base
      include AWS::S3

      def initialize(options)
        super(options)

        AWS::S3::Base.establish_connection!(
          :access_key_id => @options[:id],
          :secret_access_key => @options[:key]
        )
      end

      def validate_options
        raise "Requires id" unless @options.has_key?(:id)
        raise "Requires key" unless @options.has_key?(:key)
        @options[:prefix] ||= ''
      end

      def store(name, value)
        S3Object.store(@options[:prefix] + name, value, @options[:bucket])
      end

      def read(name)
        object = S3Object.find(@options[:prefix] + name, @options[:bucket])

        if block_given?
          object.value do |segment|
            yield segment
          end
        else
          object.value
        end
      end

      def delete(name)

      end

      def exists?(name)
        file = S3Object.find(@options[:prefix] + name, @options[:bucket]) rescue nil
        !file.nil?
      end

      def list(path = nil)
        keys = []

        Bucket.objects(@options[:bucket], :prefix => @options[:prefix] + path.to_s).each do |object|
          keys << object.key
        end

        keys
      end
    end
  end
end
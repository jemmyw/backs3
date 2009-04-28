require 'fileutils'

module Backs3
  module Storage
    class Filesystem < Backs3::Storage::Base
      def store(name, value)
        FileUtils.mkdir_p(File.dirname(whole_path(name))) rescue nil
        
        File.open(whole_path(name), 'w') do |file|
          read_data(value) do |data|
            file.write data
          end
        end
      end

      def read(name)
        if block_given?
          yield File.read(whole_path(name))
        else
          File.read(whole_path(name))
        end
      end

      def exists?(name)
        File.exists?(whole_path(name))
      end

      def list(path = nil)
        files = Dir.glob(File.join(whole_path('name'), '*'))
        files.reject{|f| File.directory?(f) || File.symlink?(f) }
      end

      def delete(path)
        File.delete(whole_path(name))
      end

      private

      def whole_path(name)
        File.join(@options[:path], name)
      end
    end
  end
end
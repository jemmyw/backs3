require 'tempfile'
require 'tarruby'

module Backs3::Storage
  class Tar < Base
    include Backs3::Storage

    def initialize(options)
      super
      retrieve_or_create_tar
    end
    
    def store(name, value)
      
    end

    def read(name)
    end

    def list(path = nil)
    end

    def exists?(name)

    end

    def delete(name)
      
    end

    def flush
      store_tar
      storage.flush
    end

    protected

    def validate_options
      @options[:tmp] = true unless @options.has_key?(:tmp)
    end

    private

    def retrieve_or_create_tar
      retrieve_tar || create_tar
    end

    def create_tar
      @file = Tempfile.new('tar')
      @file.close
    end

    def retrieve_tar
      if storage.exists?(@options[:name])
        @file = Tempfile.new('tar')
        storage.read(@options[:name]) do |data|
          @file.write data
        end
        @file.close

        true
      else
        false
      end
    end

    def store_tar
      if File.exists? @file.path
        storage.store(@options[:name], open(@file.path))
      end
    end
  end
end
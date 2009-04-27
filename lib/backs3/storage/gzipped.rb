module Backs3::Storage
  class Gzipped < Base
    include Backs3

    def initialize(options = {})
      super(options)
    end

    def store(name, value)
      # create temporary gzipped version
      File.open('/tmp/togz', 'w'){|f| f.write value}
      `gzip /tmp/togz`
      storage.store(name + '.gz', '/tmp/togz.gz')
      File.delete('/tmp/togz.gz')
    end

    def read(name)
      File.open('/tmp/togz.gz', 'w') do |f|
        storage.read(name + '.gz') do |segment|
          f.write segment
        end
      end

      `gunzip /tmp/togz.gz`

      if block_given?
        yield File.read('/tmp/togz')
      else
        File.read('/tmp/togz')
      end
    end

    def exists?(name)
      storage.exists?(name + '.gz')
    end

    def delete(name)
      storage.delete(name + '.gz')
    end
  end
end
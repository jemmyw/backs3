require 'open4'

module Backs3::Storage
  class Gzipped < Base
    include Backs3::Storage

    def initialize(options = {})
      super(options)
    end

    def store(name, value)
      pid, stdin, stdout, stderr = Open4::popen4('gzip')
      
      read_data(value) do |data|
        stdin.write data
      end
      
      stdin.close
      
      ignored, status = Process::waitpid2 pid

      if status.exitstatus == 0
        storage.store(name + '.zip', stdout)
      else
        raise 'GZIP error'
      end
    end

    def read(name)
      pid, stdin, stdout, stderr = Open4::popen('gunzip', '--stdout')

      storage.read(name + '.gz') do |segment|
        stdin.write segment
      end

      stdin.close

      ignored, status = Process::waitpid2 pid

      if status.exitstatus == 0
        if block_given?
          yield stdout.read
        else
          stdout.read
        end
      else
        raise 'GUNZIP error'
      end
    end

    def exists?(name)
      storage.exists?(name + '.gz')
    end

    def delete(name)
      storage.delete(name + '.gz')
    end

    def flush
      storage.flush
    end
  end
end
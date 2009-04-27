module Backs3
  class FileInfo
    include Backs3

    attr_reader :backup_info
    attr_reader :path
    attr_reader :md5sum

    def initialize(backup, path)
      @backup_info = backup
      @path = path
      @md5sum = md5(@path)
      @options = @backup_info.options
    end

    def storage
      @backup_info.storage
    end

    def ==(other_obj)
      other_obj.backup_info == self.backup_info && other_obj.path == self.path
    end

    def aws_filename
      File.join(@backup_info.key, path)
    end

    def backup
      logger.info "Backing up #{@path} to #{aws_filename}"
      storage.store(aws_filename, open(@path))
    end

    def restore(location = '/tmp')
      restore_path = File.join(location, @path)
      
      if storage.exists?(aws_filename)
        $stdout.write "Restoring file #{@path}"
        FileUtils.mkdir_p File.dirname(restore_path)
        File.open(restore_path, 'w') do |f|
          storage.read(aws_filename) do |segment|
            $stdout.write "."
            f.write segment
          end
        end
        $stdout.write "\n"
      else
        logger.info "Could not restore #{@path} because file data could not be found!"
      end
    end
  end
end
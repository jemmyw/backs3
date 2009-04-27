module Backs3
  class FileInfo
    include Backs3
    include AWS::S3

    attr_reader :backup_info
    attr_reader :path
    attr_reader :md5sum

    def initialize(backup, path)
      @backup_info = backup
      @path = path
      @md5sum = md5(@path)
      @options = @backup_info.options
    end

    def ==(other_obj)
      other_obj.backup_info == self.backup_info && other_obj.path == self.path
    end

    def aws_filename
      File.join(@backup_info.key, path)
    end

    def backup
      logger.info "Backing up #{@path} to #{aws_filename}"

      object = get_object

      if object.nil? || object.metadata[:md5sum] != self.md5sum
        S3Object.store(aws_filename, open(@path), @options['bucket'])
        object = S3Object.find(aws_filename, @options['bucket'])
        object.metadata[:md5sum] = self.md5sum
        object.save
      end
    end

    def restore(location = '/tmp')
      restore_path = File.join(location, @path)
      object = get_object

      if object
        $stdout.write "Restoring file #{@path}"
        FileUtils.mkdir_p File.dirname(restore_path)
        File.open(restore_path, 'w') do |f|
          object.value do |segment|
            $stdout.write "."
            f.write segment
          end
        end
        $stdout.write "\n"
      else
        logger.info "Could not restore #{@path} because file data could not be found!"
      end
    end

    private

    def get_object
      S3Object.find(aws_filename, @options['bucket']) rescue nil
    end
  end
end
module Backs3
  class BackupFileInfo
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

  class BackupInfo
    include Backs3
    
    attr_reader :date, :files, :full, :options, :last_backup, :last_full_backup, :done
  
    def initialize(previous, options)
      @backups = previous.sort{|a,b| a.date <=> b.date } if backups

      @last_backup = self.backups.last
      @last_full_backup = self.backups.reverse.detect{|b| b.full == true }

      @date = Time.now.to_i
      @options = options
      @options['prefix'] ||= ''
      @full = @options['force-full'] || first_backup? || @date - @last_full_backup.date > (@options['full'] || 7).days
    end

    def ==(other_obj)
      other_obj.date == self.date && other_obj.full == self.full
    end

    def backups
      @backups ||= load_backup_info.sort{|a,b| a.date <=> b.date } || []
    end

    # All of the files for a backup. If the backup is partial this function will
    # find the files from the last full backup to this one.
    def all_files
      if !full && @last_full_backup
        backups = self.backups.select{|b| b.date >= @last_full_backup.date && b.date <= self.date }
        backups << self unless backups.include?(self)

        rfiles = backups.collect{|b| b.files}.flatten.uniq
        rfiles.reject! do |first_file|
          rfiles.detect{|second_file| second_file.path == first_file.path && second_file.backup_info.date > first_file.backup_info.date }
        end
        rfiles
      else
        self.files
      end
    end

    def key
      @options['prefix'] + @date.to_s
    end
  
    def first_backup?
      @last_full_backup.nil?
    end
  
    def backup
      raise "Cannot backup again!" if @done
      
      logger.info "Backing up #{@options['folder']} in key #{self.key}"

      @files = collect_files
      @files.each do |file|
        file.backup
      end

      update_backup_info

      @done = true
      logger.info "Backup finished!"
    end

    def to_yaml_properties
      instance_variables.reject{|i| %w(@backups).include?(i) }.sort
    end

    private

    def update_backup_info
      raise "Cannot save info twice!" if @done

      @backups << self
      save_backup_info(@backups)
    end
  
    def collect_files
      files = begin
        Dir.glob(File.join(@options['folder'], '**', '**')).select do |file|
          if File.directory?(file) || File.symlink?(file)
            false
          else
            if @options['exclude'].blank? || file !~ /#{@options['exclude']}/
              if @full || File.mtime(file).to_i > @last_backup.date
                true
              else
                false
              end
            else
              false
            end
          end
        end
      end
    
      files.collect{|f| BackupFileInfo.new(self, f) }
    end
  end
end
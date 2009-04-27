module Backs3
  class BackupFileInfo
    include Backs3
    include AWS::S3
  
    attr_reader :backup
    attr_reader :path
    attr_reader :md5sum
  
    def initialize(backup, path)
      @backup = backup
      @path = path
      @md5sum = md5(@path)
      @options = backup.options
    end
  
    def aws_filename
      File.join(@backup.key, path)
    end

    def backup
      logger.info "Backing up #{@path} to #{aws_filename}"
    
      object = S3Object.find(aws_filename, @options['bucket']) rescue nil
    
      if object.nil? || object.metadata[:md5sum] != @md5sum
        S3Object.store(aws_filename, open(@path), @options['bucket'])
        object = S3Object.find(aws_filename, @options['bucket'])
        object.metadata[:md5sum] = @md5sum
        object.save
      end
    end
  end

  class BackupInfo
    include Backs3
    
    attr_reader :date, :files, :full, :options, :last_backup, :last_full_backup, :done
  
    def initialize(backups, options)
      backups ||= []
      @backups = backups.sort{|a,b| a.date <=> b.date }

      @last_backup = @backups.last
      @last_full_backup = @backups.reverse.detect{|b| b.full == true }

      @date = Time.now.to_i
      @options = options
      @options['prefix'] ||= ''
      @full = @options['force-full'] || first_backup? || @date - @last_full_backup.date > (@options['full'] || 7).days
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
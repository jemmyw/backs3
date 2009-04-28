module Backs3
  class Backup
    include Backs3
    include Storage

    attr_reader :date, :files, :full, :options, :last_backup, :last_full_backup, :done

    def initialize(previous, options)
      @backups = previous.sort{|a,b| a.date <=> b.date } if previous
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

    def restore(location = '/tmp', file = nil)
      files = file.nil? ? all_files : all_files.select{|f| f.path == file}
      files.each do |file|
        file.restore(location)
      end
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

      files.collect{|f| FileInfo.new(self, f) }
    end
  end
end
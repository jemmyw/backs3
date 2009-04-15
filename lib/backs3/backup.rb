require File.dirname(__FILE__) + '/backs3'

module Backs3
  class Backup
    include Backs3
    include AWS::S3

    def initialize(options = {})
      @options = options
      @options['prefix'] ||= ''
    end

    def first_backup?
      last_backup.nil?
    end

    def full_backup
      @options['force-full'] || first_backup? || Time.now.to_i - last_backup > (@options['full'] || 7).days
    end

    def last_backup
      backup_info['last_backup'].to_i
    end

    def backup_key
      @options['prefix'] + @current_backup
    end

    def last_key
      @options['prefix'] + last_backup.to_s
    end

    def files_to_backup
      @files_to_backup ||= begin
        Dir.glob(File.join(@options['folder'], '**', '**')).select do |file|
          if File.directory?(file)
            false
          else
            if @options['exclude'].blank? || file !~ /#{@options['exclude']}/
              if full_backup || File.mtime(file).to_i > last_backup
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
    end

    def backup
      @current_backup = Time.now.to_i.to_s
      @files_to_backup = nil
      @backup_info = nil

      establish_connection

      puts "Backup started at #{Time.now}"
      puts "Last backup happened at #{backup_info['last_backup']}"
      puts "Performing %s" % (full_backup ? "full backup" : "incremental backup")

      files_to_backup.each do |filename|
        puts "Backing up #{filename}"
        file_md5 = md5(filename)
        aws_filename = File.join(backup_key, filename)

        object = S3Object.find(aws_filename, @options['bucket']) rescue nil

        if object.nil? || object.metadata[:md5sum] != file_md5
          S3Object.store(aws_filename, open(filename), @options['bucket'])
          object = S3Object.find(aws_filename, @options['bucket'])
          object.metadata[:md5sum] = file_md5
          object.save
        end
      end

      backup_info['last_backup'] = @current_backup
      backup_info['backups'] ||= []
      backup_info['backups'] << @current_backup
      S3Object.store(@options['prefix'] + 's3backup', YAML.dump(backup_info), @options['bucket'])
      puts "Backup completed, #{files_to_backup.size} files backed up"
    end
  end
end
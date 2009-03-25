require File.dirname(__FILE__) + '/backs3'
require 'fileutils'

module Backs3
  class Restore
    include Backs3
    include AWS::S3

    def self.commands
      %w(ls available restore cat)
    end

    def initialize(options = {})
      @options = options
      @options['prefix'] ||= ''
      establish_connection
    end

    def available(file = nil)
      if file.nil?
        puts "Backups available: #{backup_info['backups'].join(", ")}"
      else
        info = backup_info['backups'].collect do |backup|
          backup_key = @options['prefix'] + backup.to_s
          object = S3Object.find(File.join(backup_key, file), @options['bucket']) rescue nil

          if object
            {
              :backup => backup,
              :md5 => object.metadata[:md5sum]
            }
          else
            nil
          end

        end.compact

        puts "Backup information for #{file}:"
        info.each do |i|
          puts "\tBackup #{i[:backup]}: #{i[:md5]}"
        end

      end
    end

    def ls(backup)
      Bucket.objects(@options['bucket'], :prefix => @options['prefix'] + backup.to_s).each do |object|
        puts object.key
      end
    end

    def cat(backup, file)
      backup_key = @options['prefix'] + backup.to_s
      object = S3Object.find(File.join(backup_key, file), @options['bucket']) rescue nil
      
      if object.nil?
        puts "Cannot find file #{file}"
      else
        puts object.value(:reload)
      end
    end

    def restore(backup, file = nil)
      backup_key = @options['prefix'] + backup.to_s
      objects = []

      if file.nil?
        objects = Bucket.objects(@options['bucket'], :prefix => @options['prefix'] + backup.to_s)
      else
        objects << S3Object.find(File.join(backup_key, file), @options['bucket']) rescue nil
      end

      objects.compact!

      objects.each do |object|
        $stdout.write "Restoring file #{object.key} to /tmp/#{object.key}"
        filename = "/tmp/#{object.key}"
        FileUtils.mkdir_p File.dirname(filename)
        File.open(filename, 'w') do |f|
          object.value do |segment|
            $stdout.write "."
            f.write segment
          end
        end
        $stdout.write "\n"
      end
    end
  end
end
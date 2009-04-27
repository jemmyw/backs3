require File.dirname(__FILE__) + '/backs3'
require 'fileutils'

module Backs3
  class Restore
    include Backs3
    include AWS::S3

    def self.commands
      %w(ls available restore cat info)
    end

    def initialize(options = {})
      @options = options
      @options['prefix'] ||= ''
      establish_connection
      @backups = load_backup_info
    end

    def available(backup_key = nil)
      if backup_key.nil?
        puts "Backups available: #{@backups.map{|b| b.date}.join(", ")}"
      else
        unless backup = @backups.detect{|b| b.date.to_s == backup_key.to_s }
          raise "No backup #{backup_key} available"
        end

        backups = [backup]

        if !backup.full && backup.last_full_backup
          @backups.each do |b|
            backups << b if b.date >= backup.last_full_backup.date && b.date < backup.date
          end
        end
        
        files = backups.collect{|b| b.files}.flatten
        files.reject!{|f| !f.backup_info.respond_to?(:date) }
        
        files.reject! do |f|
          files.detect{|of| of.path == f.path && of.backup_info.date > f.backup_info.date }
        end

        puts "Backup information for #{backup.date}"
        files.each do |file|
          puts "\tFile: #{file.path}, backed up #{Time.at(file.backup_info.date).to_s}"
        end
      end
    end

    def info(file)
      files = @backups.collect{|b| b.files}.flatten.select{|f| f.path == file}

      if files.empty?
        puts "No information found for file #{file}"
      else
        puts "Backup information for file #{file}"

        files.each do |f|
          puts "\tBacked up #{Time.at(f.backup_info.date).to_s} in #{f.backup_info.date} with md5sum #{f.md5sum}"
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
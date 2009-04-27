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
      @backups = load_backup_info.sort{|a,b| a.date <=> b.date }
    end

    def available(backup_key = nil)
      if backup_key.nil?
        puts "Backups available: #{@backups.map{|b| b.date}.join(", ")}"
      else
        unless backup = @backups.detect{|b| b.date.to_s == backup_key.to_s }
          raise "No backup #{backup_key} available"
        end

        files = backup.all_files

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

    def restore(date, file = nil)
      backup = @backups.detect{|b| b.date.to_s == date.to_s}
      raise 'Cannot find backup %s' % date if backup.nil?
      backup.restore('/tmp', file)
    end
  end
end
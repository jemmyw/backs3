# #!/usr/bin/env ruby

require 'rubygems' rescue nil
require 'aws/s3'
require 'active_support'
require 'active_support/dependencies'
require 'digest/md5'
require 'time'

unless ActiveSupport::Dependencies.load_paths.include?(File.expand_path(File.dirname(__FILE__) + '/..'))
  ActiveSupport::Dependencies.load_paths << File.expand_path(File.dirname(__FILE__) + '/..')
end

module Backs3
  autoload :Backup, 'backs3/backup'
  autoload :FileInfo, 'backs3/file_info'

  def self.included(base) #:nodoc:
    base.class_eval do
      def lookup_storage(name, options)
        storage_class = Backs3::Storage.const_get(name.to_s.camelize)
        storage_class.new(options)
      end
    end
  end

  def storage
    @storage ||= self.class.lookup_storage(@options['storage'] || :aws, @options['storage_options'])
  end

  def logger
    logger_output = @options['logger'] || $stdout
    @logger ||= Logger.new(logger_output)
  end

  def md5(filename)
    Digest::MD5.hexdigest(filename)
  end
  
  def save_backup_info(info)
    storage.store('s3backup', YAML.dump(info))
    logger.info "Backup info has been stored"
  end

  def load_backup_info
    @backups ||= begin
      backup_info_file = storage.read('s3backup') || nil
      YAML.load(backup_info_file) || []
    rescue Exception => e
      puts e.to_s
      []
    end
    
    unless @backups.respond_to?(:sort) && @backups.respond_to?(:each) && @backups.respond_to?(:reject!)
      @backups = []
    end
    
    @backups.reject! do |backup|
      !backup.respond_to?(:date)
    end
    
    @backups.sort do |a,b|
      a.date <=> b.date
    end
    
    @backups
  end
end
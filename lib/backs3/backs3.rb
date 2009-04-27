# #!/usr/bin/env ruby

require 'rubygems' rescue nil
require 'aws/s3'
require 'active_support'
require 'digest/md5'
require 'time'
require File.join(File.dirname(__FILE__), 'backup_info')

$has_md5 = !(`which md5`).blank?

module Backs3
  include AWS::S3
  
  def logger
    logger_output = @options['logger'] || $stdout
    @logger ||= Logger.new(logger_output)
  end

  def establish_connection
    AWS::S3::Base.establish_connection!(
      :access_key_id => @options['id'],
      :secret_access_key => @options['key']
    )
  end

  def md5(filename)
    if $has_md5
      `md5 -q #{filename}`
    else
      Digest::MD5.hexdigest(filename)
    end
  end
  
  def save_backup_info(info)
    S3Object.store(@options['prefix'] + 's3backup', YAML.dump(info), @options['bucket'])
    logger.info "Backup info has been stored"
  end

  def load_backup_info
    @backups ||= begin
      backup_info_file = S3Object.find(@options['prefix'] + 's3backup', @options['bucket'])
      backup_info_data = backup_info_file.value(:reload)
      YAML.load(backup_info_data) || {}      
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
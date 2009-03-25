# #!/usr/bin/env ruby

require 'rubygems' rescue nil
require 'aws/s3'
require 'active_support'
require 'digest/md5'
require 'time'

$has_md5 = !(`which md5`).blank?

module Backs3
  include AWS::S3

  def establish_connection
    AWS::S3::Base.establish_connection!(
      :access_key_id => @options['id'],
      :secret_access_key => @options['key']
    )
  end

  def md5(filename)
    if $has_md5
      `md5 #{filename}`
    else
      Digest::MD5.hexdigest(filename)
    end
  end

  def backup_info
    @backup_info ||= begin
      backup_info_file = S3Object.find(@options['prefix'] + 's3backup', @options['bucket'])
      backup_info_data = backup_info_file.value(:reload)
      YAML.load(backup_info_data) || {}
    rescue Exception => e
      puts e.to_s
      {}
    end
  end
end
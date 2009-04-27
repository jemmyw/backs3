require File.dirname(__FILE__) + '/backs3'

module Backs3
  class Backup
    include Backs3

    def initialize(options = {})
      @options = options
      @options['prefix'] ||= ''

      establish_connection
      
      @backups = load_backup_info      
      @backup = BackupInfo.new(@backups, @options)
    end

    def backup
      @backup.backup
    end
  end
end
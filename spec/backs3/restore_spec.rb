require File.dirname(__FILE__) + "/../spec_helper"
require 'backs3/restore'

describe Backs3::Restore do
  before(:each) do
    AWS::S3::Base.stub!(:establish_connection!)
    @bucket = 'test_bucket'
    @restore = Restore.new('bucket' => @bucket)

    @file_1 = mock(:s3object, :metadata => {})

    @backup_mock1 = mock(:backup_info, :date => 12345, :full => true)
    @backup_mock2 = mock(:backup_info, :date => 54321, :last_full_backup => @backup_mock1, :full => false)

    @file_mock1 = mock(:file, :backup_info => @backup_mock1, :path => 'test/file_1')
    @file_mock2 = mock(:file, :backup_info => @backup_mock1, :path => 'test/file_2')
    @file_mock3 = mock(:file, :backup_info => @backup_mock1, :path => 'test/file_3')
    @file_mock4 = mock(:file, :backup_info => @backup_mock2, :path => 'test/file_1')
    
    @files_mock1 = [
      @file_mock1, @file_mock2, @file_mock3
    ]

    @files_mock2 = [
      @file_mock4
    ]

    @files_mock3 = [
      @file_mock4, @file_mock2, @file_mock3
    ]

    @backup_mock1.stub!(:files).and_return(@files_mock1)
    @backup_mock2.stub!(:files).and_return(@files_mock2)

    @backup_mock1.stub!(:all_files).and_return(@files_mock1)
    @backup_mock2.stub!(:all_files).and_return(@files_mock3)

    @backup_array = [@backup_mock1, @backup_mock2]
    @restore.stub!(:load_backup_info).and_return(@backup_array)
    @restore.instance_variable_set('@backups', @backup_array)
  end

  describe 'self.commands' do
    it 'should return an array' do
      Restore.commands.should be_a(Array)
    end
  end

  describe 'available' do
    it 'should list all of the backups available' do
      @restore.should_receive(:puts).with('Backups available: 12345, 54321')
      @restore.available
    end

    it 'should list all of the available files in a full backup' do
      @restore.should_receive(:puts).once.with('Backup information for 12345')
      @restore.should_receive(:puts).once.with("\tFile: test/file_1, backed up #{Time.at(12345).to_s}")
      @restore.should_receive(:puts).once.with("\tFile: test/file_2, backed up #{Time.at(12345).to_s}")
      @restore.should_receive(:puts).once.with("\tFile: test/file_3, backed up #{Time.at(12345).to_s}")

      @restore.available(12345)
    end

    it 'should list all the files from the last full backup for a partial backup' do
      @restore.should_receive(:puts).once.with('Backup information for 54321')
      @restore.should_receive(:puts).once.with("\tFile: test/file_1, backed up #{Time.at(54321).to_s}")
      @restore.should_receive(:puts).once.with("\tFile: test/file_2, backed up #{Time.at(12345).to_s}")
      @restore.should_receive(:puts).once.with("\tFile: test/file_3, backed up #{Time.at(12345).to_s}")

      @restore.available(54321)
    end
  end

  describe 'ls' do
    it 'should list all of the files in a directory'
  end

  describe 'cat' do
    it 'should show an error if the file specified does not exist'
    it 'should output the contents of a file'
  end

  describe 'restore' do
    it 'should restore a whole backup if no file is specified'
    it 'should restore a file'
  end
end
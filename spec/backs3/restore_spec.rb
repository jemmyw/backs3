require File.dirname(__FILE__) + "/../spec_helper"
require 'backs3/restore'

include Backs3

describe Restore do
  before(:each) do
    AWS::S3::Base.stub!(:establish_connection!)
    @bucket = 'test_bucket'
    @restore = Restore.new('bucket' => @bucket)

    @file_1 = mock(:s3object, :metadata => {})
  end

  describe 'self.commands' do
    it 'should return an array' do
      Restore.commands.should be_a(Array)
    end
  end

  describe 'available' do
    it 'should list all of the backups available if no file is specified' do
      @restore.should_receive(:backup_info).and_return({'backups' => [12345, 54321]})
      @restore.should_receive(:puts).with('Backups available: 12345, 54321')
      @restore.available
    end
    it 'should list all of the backups a file is in' do
      file = 'test/file_1'
      @restore.should_receive(:backup_info).and_return({'backups' => [12345, 54321]})
      S3Object.should_receive(:find).with('12345/test/file_1', @bucket).and_return(@file_1)
      S3Object.should_receive(:find).with('54321/test/file_1', @bucket).and_return(nil)

      @restore.should_receive(:puts).with('Backup information for test/file_1:')
      @restore.should_receive(:puts).with("\tBackup 12345: ")
      @restore.should_not_receive(:puts).with("\tBackup 54321: ")

      @restore.available(file)
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
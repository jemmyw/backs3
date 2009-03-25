require File.dirname(__FILE__) + "/../spec_helper"
require 'backs3/backup'
include Backs3

describe Backup do
  before(:each) do
    AWS::S3::Base.stub!(:establish_connection!)
    @bucket = 'test_bucket'
    @backup = Backup.new({'bucket' => @bucket})
  end

  describe 'backup' do
    it 'should backup all the files returned by files_to_backup'
  end

  describe 'first_backup?' do
    it 'should be true if there is no previous backup' do
      @backup.should_receive(:last_backup).and_return(nil)
      @backup.first_backup?.should be_true
    end

    it 'should be false if there is a previous backup' do
      @backup.should_receive(:last_backup).and_return(12345)
      @backup.first_backup?.should be_false
    end
  end

  describe 'full_backup' do
    it 'should be true if force-full option is set' do
      @backup = Backup.new('force-full' => true)
      @backup.should_not_receive(:last_backup)
      @backup.should_not_receive(:first_backup?)
      @backup.full_backup.should be_true
    end
    it 'should be true if this is the first backup' do
      @backup.should_receive(:first_backup?).and_return(true)
      @backup.full_backup.should be_true
    end
    it 'should be true if the last backup was more than 7 days ago' do
      @backup.should_receive(:first_backup?).and_return(false)
      @backup.should_receive(:last_backup).and_return((Time.now - 8.days).to_i)
      @backup.full_backup.should be_true
    end
    it 'should be false' do
      @backup.should_receive(:first_backup?).and_return(false)
      @backup.should_receive(:last_backup).and_return(Time.now.to_i)
      @backup.full_backup.should be_false
    end
  end

  describe 'last_backup' do
    it 'should return the integer time of the last backup' do
      time = Time.now
      time.should_receive(:to_i).and_return(12345)
      @backup.should_receive(:backup_info).and_return({'last_backup' => time})
      @backup.last_backup.should == 12345
    end
  end

  describe 'backup_key' do
    it 'should return the prefix + the backup time'
  end

  describe 'last_key' do
    it 'should return the prefix + the last backup time'
  end

  describe 'files_to_backup' do
    it 'should return all the files in the backup folder'
    it 'should not return excluded files'
    it 'should not return files that have not changed if this is an incremental backup'
  end
end
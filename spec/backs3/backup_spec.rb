require File.dirname(__FILE__) + "/../spec_helper"
require 'backs3/backs3'
require 'backs3/backup'

describe Backs3::Backup do
  before(:each) do
    @options = {'folder' => 'test', 'logger' => StringIO.new(''), 'storage' => 'test'}
    @previous = []
  end
  
  it 'should set the date to Time.now.to_i' do
    @mock_time = mock(:time)
    @mock_time.should_receive(:to_i).and_return(1)
    Time.should_receive(:now).and_return(@mock_time)
    
    Backup.new(@previous, @options).date.should == 1
  end

  describe 'backup' do
    before(:each) do
      @file_info = mock(:file_info)
      @backup = Backup.new(@previous, @options)
    end

    it 'should call backup on each file in the backup folder' do
      @backup.should_receive(:save_backup_info).once
      @file_info.should_receive(:backup).exactly(3).times

      (1..3).each do |f|
        FileInfo.should_receive(:new).with(@backup, 'test/file_%d' % f).and_return(@file_info)
      end

      @backup.backup
    end

    it 'should exclude files based on the exclude option' do
      @options['exclude'] = 'file_1'
      @backup = Backup.new(@previous, @options)
      @backup.should_receive(:save_backup_info).once

      @file_info.should_receive(:backup).exactly(2).times

      (2..3).each do |f|
        FileInfo.should_receive(:new).with(@backup, 'test/file_%d' % f).and_return(@file_info)
      end

      @backup.backup
    end
  end

  describe 'full_backup?' do
    it 'should be false if there is a previous full backup' do
      @previous << mock(:backup, :date => Time.now.to_i, :full => true)
      Backup.new(@previous, @options).first_backup?.should == false
    end

    it 'should be true if there are no previous full backups' do
      Backup.new(@previous, @options).first_backup?.should == true
      @previous << mock(:backup, :date => Time.now.to_i, :full => false)
      Backup.new(@previous, @options).first_backup?.should == true
    end
  end

  describe 'all_files' do
    it 'should just be the list of files in the backup if the backup is full' do
      backup = Backup.new(@previous, @options)
      backup.full.should == true
      backup.all_files.should == backup.files
    end

    it 'should include files from the last full backup if partial' do
      last_full = Backup.new([], @options)
      last_full.stub!(:full).and_return(true)

      current = Backup.new([last_full], @options)
      current.stub!(:full).and_return(false)

      file_1 = mock(:file_info, :path => 'test/file_1', :backup_info => last_full)
      file_2 = mock(:file_info, :path => 'test/file_2', :backup_info => current)

      last_full.stub!(:files).and_return([file_1])
      current.stub!(:files).and_return([file_2])

      current.all_files.should == [file_1, file_2]
    end
  end

  describe '@full' do
    it 'should set full if there is no previous backup specified' do
      Backup.new(@previous, @options).full.should == true
    end

    it 'should always set full if there is no full previous backup' do
      (1..10).each do |d|
        @previous << mock(:backup, :date => Time.now.to_i - d.days, :full => false)
        Backup.new(@previous, @options).full.should == true
      end
    end
  
    it 'should set full if the previous backup happened more than 7 days ago' do
      @previous << mock(:backup, :date => Time.now.to_i - 8.days, :full => true)
      Backup.new(@previous, @options).full.should == true
    end
  
    it 'should set full to false if the previous backup happened less than 7 days ago' do
      @previous << mock(:backup, :date => Time.now.to_i - 6.days, :full => true)
      Backup.new(@previous, @options).full.should == false
    end

    it 'should set full if the previous backup happened more than options full' do
      @options['full'] = 5
      @previous << mock(:backup, :date => Time.now.to_i - 6.days, :full => true)
      Backup.new(@previous, @options).full.should == true
    end

    it 'should not set full if the previous backup happened less than options full days ago' do
      @options['full'] = 5
      @previous << mock(:backup, :date => Time.now.to_i - 4.days, :full => true)
      Backup.new(@previous, @options).full.should == false
    end

    it 'should always set full if the force full backup options is passed' do
      @options['force-full'] = true
      Backup.new(@previous, @options).full.should == true

      (1..10).each do |d|
        @previous << mock(:backup, :date => Time.now.to_i - d.days, :full => true)
        Backup.new(@previous, @options).full.should == true
      end
    end
  end
end
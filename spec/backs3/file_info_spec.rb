require File.dirname(__FILE__) + "/../spec_helper"
require 'backs3/backs3'
require 'backs3/file_info'

include Backs3

describe Backs3::FileInfo do
  before(:each) do
    @options = {'folder' => 'test', 'logger' => StringIO.new(''), 'bucket' => 'test_bucket'}
    @backup = mock(:backup)
    @path = 'test/file_1'

    @backup.stub!(:options).and_return(@options)
  end

  describe 'aws_filename' do
    it 'should return the full filename to be put on aws' do
      @backup.should_receive(:key).and_return('12345')
      FileInfo.new(@backup, @path).aws_filename.should == '12345/test/file_1'
    end
  end

  describe '==' do
    it 'should be equal if files have same path and same backup info' do
      file_1 = FileInfo.new(@backup, @path)
      file_2 = FileInfo.new(@backup, @path)
      file_1.should == file_2
    end

    it 'should be different if files have different path' do
      file_1 = FileInfo.new(@backup, @path)
      file_2 = FileInfo.new(@backup, @path + 'diff')
      file_1.should_not == file_2
    end

    it 'should be different if files have different backup' do
      @backup2 = mock(:backup)
      @backup2.stub!(:options).and_return(@options)
      file_1 = FileInfo.new(@backup, @path)
      file_2 = FileInfo.new(@backup2, @path)
      file_1.should_not == file_2
    end
  end

  describe 'backup' do
    before(:each) do
      @s3 = mock(:s3)
      @backup.stub!(:key).and_return('12345')
    end

    it 'should do nothing if the file is on S3 and the same as the current file' do
      S3Object.should_receive(:find).with('12345/test/file_1', 'test_bucket').and_return(@s3)
      S3Object.should_not_receive(:store)
      @s3.should_receive(:metadata).and_return({:md5sum => 'abcde'})

      @info = FileInfo.new(@backup, @path)
      @info.should_receive(:md5sum).and_return('abcde')
      @info.backup
    end

    it 'should upload the file if it is not on S3' do
      S3Object.should_receive(:find).with('12345/test/file_1', 'test_bucket').and_return(nil, @s3)
      S3Object.should_receive(:store)
      @s3.should_receive(:metadata).and_return({:md5sum => 'abcde'})
      @s3.should_receive(:save).and_return(true)

      @info = FileInfo.new(@backup, @path)
      @info.should_receive(:md5sum).and_return('abcde')
      @info.backup
    end

    it 'should upload the file if it is on S3 but the md5sum is different' do
      S3Object.should_receive(:find).with('12345/test/file_1', 'test_bucket').and_return(@s3, @s3)
      S3Object.should_receive(:store)
      @s3.should_receive(:metadata).twice.and_return({:md5sum => 'abcd'})
      @s3.should_receive(:save).and_return(true)

      @info = FileInfo.new(@backup, @path)
      @info.should_receive(:md5sum).twice.and_return('abcde')
      @info.backup
    end
  end
end

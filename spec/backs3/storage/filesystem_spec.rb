require File.dirname(__FILE__) + "/../../spec_helper"
require 'backs3/backs3'
require 'backs3/storage/filesystem'

describe Backs3::Storage::Filesystem do
  before(:each) do
    @store = Backs3::Storage::Filesystem.new(:path => 'test')
    @mock_file = mock(:file)
  end

  describe 'store' do
    it 'should write to a file' do
      File.should_receive(:open).with('test/file_1', 'w').and_yield(@mock_file)
      @mock_file.should_receive(:write).with('test data')
      @store.store('file_1', 'test data')
    end

    it 'should write to a file with a stream' do
      File.should_receive(:open).with('test/file_1', 'w').and_yield(@mock_file)
      @mock_file.should_receive(:write).with('test data')
      @store.store('file_1', StringIO.new('test data'))
    end
  end
end
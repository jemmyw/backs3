require File.dirname(__FILE__) + "/../../spec_helper"
require 'backs3/backs3'
require 'backs3/storage/aws'

describe Backs3::Storage::Aws do
  before(:each) do
    AWS::S3::Base.should_receive(:establish_connection!).with(
      :access_key_id => 'test id',
      :secret_access_key => 'test key'
    )
    @store = Backs3::Storage::Aws.new(:id => 'test id', :key => 'test key', :bucket => 'test bucket')
  end
  
  describe 'store' do
    it 'should store the file on s3' do
      AWS::S3::S3Object.should_receive(:store).with('file_1', 'test data', 'test bucket')
      @store.store('file_1', 'test data')
    end

    it 'should store the file on s3 reading from an IO object' do
      AWS::S3::S3Object.should_receive(:store).with('file_1', anything(), 'test bucket')
      @store.store('file_1', StringIO.new('test data'))
    end
  end
end
require File.dirname(__FILE__) + "/../spec_helper"
require 'backs3/backup'
include Backs3

describe Backup do
  before(:each) do
    AWS::S3::Base.stub!(:establish_connection!)
    @bucket = 'test_bucket'
    @backup = Backup.new({'bucket' => @bucket})
  end
end
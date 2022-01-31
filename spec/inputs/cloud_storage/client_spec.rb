# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/google_cloud_storage'
require 'logstash/inputs/cloud_storage/client'

describe LogStash::Inputs::CloudStorage::Client do

  # This test is mostly to make sure the Java types, signatures and classes
  # haven't changed being that JRuby is very relaxed.
  describe '#initialize' do
    let(:logger) { spy('logger') }

    it 'does not throw an error when initializing' do
      key_file = ::File.join('spec', 'fixtures', 'credentials.json')
      LogStash::Inputs::CloudStorage::Client.new('my-bucket', 'blob-prefix', key_file, logger)
    end
  end
end

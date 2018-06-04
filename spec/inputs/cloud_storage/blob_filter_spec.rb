# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/google_cloud_storage'
require 'logstash/inputs/cloud_storage/blob_filter'
require 'logstash/inputs/cloud_storage/blob_adapter'

describe LogStash::Inputs::CloudStorage::BlobFilter do
  describe '#initialize' do
    it 'should fail with invalid match regex' do
      expect { make_filter(:include_regex => '(') }.to raise_error(RuntimeError)
    end

    it 'should fail with invalid exclude regex' do
      expect { make_filter(:exclude_regex => '(') }.to raise_error(RuntimeError)
    end
  end

  describe '#should_process?' do
    let(:java_blob) do
      double('Blob',
             :getBucket => 'bucket',
             :getMetadata => { 'some-tag' => 'true' },
             :getName => 'path/to/log.log.gz',
             :getMd5 => 'md5',
             :getCrc32c => 'crc',
             :getGeneration => 123,
             :downloadTo => true)
    end
    let(:blob) { LogStash::Inputs::CloudStorage::BlobAdapter.new(java_blob) }
    let(:passdb) { double('passdb', :already_processed? => false) }
    let(:faildb) { double('passdb', :already_processed? => true) }

    it 'should be able to pass with a blob that meets all conditions' do
      subject = make_filter

      expect(subject.should_process?(blob)).to eq(true)
    end

    it 'should fail if a blob is in the processed database' do
      subject = make_filter(:processed_db => faildb)

      expect(subject.should_process?(blob)).to eq(false)
    end

    it 'should fail if a blob does not match the include regex' do
      subject = make_filter(:include_regex => '.*.json')

      expect(subject.should_process?(blob)).to eq(false)
    end

    it 'should fail if a blob matches the exclude regex' do
      subject = make_filter(:exclude_regex => '.*')

      expect(subject.should_process?(blob)).to eq(false)

    end

    it 'should fail if it has an already processed metadata tag' do
      subject = make_filter(:metadata_key => 'some-tag')

      expect(subject.should_process?(blob)).to eq(false)

    end
  end

  def make_filter(options = {})
    logger = spy('logger')

    LogStash::Inputs::CloudStorage::BlobFilter.new(
      logger,
      options[:include_regex] || '.*',
      options[:exclude_regex] || '^$',
      options[:metadata_key] || '',
      options[:processed_db] || nil
    )
  end
end

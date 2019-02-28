# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/google_cloud_storage'
require 'logstash/inputs/cloud_storage/blob_adapter'

describe LogStash::Inputs::CloudStorage::BlobAdapter do
  let(:blob) do
    double('Blob',
      :getBucket => 'bucket',
      :getMetadata => {},
      :getName => 'name',
      :getMd5 => 'md5',
      :getCrc32c => 'crc',
      :getGeneration => 123,
      :downloadTo => true)
  end
  subject { LogStash::Inputs::CloudStorage::BlobAdapter.new(blob) }

  describe '#attributes' do
    it 'includes the bucket ID as bucket' do
      expect(subject.attributes).to have_key('bucket')
    end

    it 'includes metadata as metadata' do
      expect(subject.attributes).to have_key('metadata')
    end

    it 'includes the blob name as name' do
      expect(subject.attributes).to have_key('name')
    end

    it 'includes the md5 as md5' do
      expect(subject.attributes).to have_key('md5')
    end

    it 'includes the crc32c as crc32c' do
      expect(subject.attributes).to have_key('crc32c')
    end

    it 'includes the generation as generation' do
      expect(subject.attributes).to have_key('generation')
    end
  end

  describe '#line_attributes' do
    it 'sets line_id to the correct format' do
      attrs = subject.line_attributes(9876)
      expect(attrs['line_id']).to eq('gs://bucket/name:9876@123')
    end

    it 'includes line' do
      attrs = subject.line_attributes(9876)
      expect(attrs['line']).to eq(9876)
    end
  end

  describe '#with_downloaded' do
    before(:each) do
      allow(FileUtils).to receive(:remove_entry_secure)
    end

    it 'uses temp_directory as a base' do
      expect { |b| subject.with_downloaded('foo', &b) }.to yield_with_args(/foo.*/)
    end

    it 'calls downloadTo on the blob' do
      expect(blob).to receive(:downloadTo)
      subject.with_downloaded('foo') {}
    end

    it 'yields the downloaded file' do
      expect { |b| subject.with_downloaded('foo', &b) }.to yield_with_args(String)
    end

    it 'securely deletes the file once done' do
      expect(FileUtils).to receive(:remove_entry_secure)
      subject.with_downloaded('foo') {}
    end
  end
end

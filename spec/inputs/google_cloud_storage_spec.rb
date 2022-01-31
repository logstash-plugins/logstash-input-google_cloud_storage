# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/google_cloud_storage'
require 'logstash/inputs/cloud_storage/client'
require 'logstash/inputs/cloud_storage/blob_filter'
require 'logstash/inputs/cloud_storage/blob_adapter'
require 'stud/temporary'

describe LogStash::Inputs::GoogleCloudStorage do

  let(:processed_db_dir) { Stud::Temporary.pathname }
  let(:download_dir) { Stud::Temporary.pathname }

  let(:config) {
    {
        'bucket_id' => 'test-bucket-id',
        'json_key_file' => ::File.join('spec', 'fixtures', 'credentials.json'),
        'blob_prefix' => 'test-prefix',
        'file_matches' => '.*log',
        'file_exclude' => 'bak-.*',
        'metadata_key' => 'test-metadata',
        'processed_db_path' => processed_db_dir,
        'temp_directory' => download_dir,
        'delete' => true,
        'unpack_gzip' => false
    }
  }

  describe '#register' do
    it 'accepts valid configuration' do
      subject = LogStash::Inputs::GoogleCloudStorage.new(config)
      expect { subject.register }.to_not raise_error(RuntimeError)
    end

    it 'fails with invalid configuration' do
      bad = config.merge({'file_matches' => ')'})
      subject = LogStash::Inputs::GoogleCloudStorage.new(bad)
      expect { subject.register }.to raise_error(RuntimeError)
    end
  end

  describe '#list_download_process' do
    let(:blobs) { mock_blob_list('match.log', 'mismatch.log.xz', 'bak-log.log') }
    let(:client) do
      dbl = double('client')

      allow(dbl).to receive(:list_blobs).and_yield(blobs[0]).and_yield(blobs[1]).and_yield(blobs[2])

      dbl
    end

    subject { LogStash::Inputs::GoogleCloudStorage.new(config) }

    before :each do
      expect(LogStash::Inputs::CloudStorage::Client).to receive(:new).and_return(client)
      subject.event_output_queue = []
      subject.register
    end


    it 'lists files' do
      expect(subject.processed_db).to receive(:already_processed?).exactly(3).times
      subject.list_download_process
    end

    it 'produces events for matching files' do
      subject.list_download_process

      events = subject.event_output_queue

      messages = events.map { |e| e.get('message') }
      expect(messages).to eq(["match.log1\r\n", "match.log2"])

      filenames = events.map { |e| e.get('[@metadata][gcs][name]') }
      expect(filenames).to eq(['match.log', 'match.log'])
    end

    it 'post-processes matching files' do
      matching = blobs[0]

      expect(matching).to receive(:set_metadata!)
      expect(matching).to receive(:delete!)

      subject.list_download_process

      expect(subject.processed_db.already_processed?(matching)).to eq(true)
    end
  end

  def mock_blob_list(*names)
    names.map { |name| mock_blob(name) }
  end

  def mock_blob(name)
    generation = rand 2**64

    java_blob = double('Blob',
                       :getBucket => 'bucket',
                       :getMetadata => { 'some-tag' => 'true' },
                       :getName => name,
                       :getMd5 => 'md5',
                       :getCrc32c => 'crc',
                       :getGeneration => generation)

    java_blob.stub_chain(:toBuilder, :setMetadata, :build, :update).and_return(true)
    java_blob.stub(:downloadTo) do |path|
      File.open(path.toString, 'w') { |file| file.write("#{name}1\r\n#{name}2") }
    end
    java_blob.stub(:delete).and_return(true)

    LogStash::Inputs::CloudStorage::BlobAdapter.new(java_blob)
  end
end

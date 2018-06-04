# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/google_cloud_storage'
require 'logstash/inputs/cloud_storage/processed_db'

describe LogStash::Inputs::CloudStorage::ProcessedDb do

  let(:blob) { double('blob', :name => 'foo', :generation => 12_345) }
  subject { LogStash::Inputs::CloudStorage::ProcessedDb.new('base') }

  describe '#encode_path' do
    it 'includes the generation in the hash' do
      blob2 = double('blob2', :name => 'foo', :generation => 54_321)

      expect(subject.encode_path(blob)).to_not eq(subject.encode_path(blob2))
    end

    it 'includes the path in the hash' do
      blob2 = double('blob2', :name => 'bar', :generation => 12_345)

      expect(subject.encode_path(blob)).to_not eq(subject.encode_path(blob2))
    end

    it 'includes the base directory in the path' do
      path = subject.encode_path(blob)

      expect(path.start_with?('base')).to eq(true)
    end

    it 'splits the path into base/3/rest' do
      path = subject.encode_path(blob)
      parts = path.split(::File::SEPARATOR)

      expect(parts.length).to eq(3)
      expect(parts[0]).to eq('base')
      expect(parts[1].length).to eq(3)
    end

    it 'produces a correct SHA1 path' do
      expected = ::File.join('base', 'd27', '628eefc02ae87401aea8c57c49579fbd6b55e')

      expect(subject.encode_path(blob)).to eq(expected)
    end
  end

  # The tight coupling of the tests to already_processed? and mark_processed
  # is intentional.
  # It's critical the implementation remains the same between versions
  # so upgrading the plugin version won't trigger a full re-index of a bucket.

  describe '#already_processed?' do
    it 'checks if the path returned from encode_path exists' do
      allow(subject).to receive(:encode_path).and_return('path/to/create')
      expect(::File).to receive(:exist?).with('path/to/create')

      subject.already_processed?(blob)
    end
  end

  describe '#mark_processed' do
    it 'creates the directory and parent dirs for encode_path' do
      allow(subject).to receive(:encode_path).and_return('path/to/create')

      subject.already_processed?(blob)
    end
  end
end

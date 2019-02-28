# encoding: utf-8

require 'logstash/devutils/rspec/spec_helper'
require 'logstash/inputs/google_cloud_storage'
require 'logstash/inputs/cloud_storage/file_reader'

describe LogStash::Inputs::CloudStorage::FileReader do
  describe '#gzip?' do
    GzipTest = Struct.new('GzipTest', :path, :expected)

    it 'is true when the file ends with .gz' do
      cases = [
        GzipTest.new('simple.gz', true),
        GzipTest.new('subdir/simple.gz', true),
        GzipTest.new('/abs/path.gz', true),
        GzipTest.new('path.log.gz', true),

        GzipTest.new('path.log.gzip', false),
        GzipTest.new('simple.log', false),
        GzipTest.new('simple.gz/foo', false),
        GzipTest.new('simple.gz.log', false),
        GzipTest.new('foo.tgz', false)
      ]

      cases.each do |test|
        result = LogStash::Inputs::CloudStorage::FileReader.gzip?(test.path)

        expect(result).to eq(test.expected)
      end
    end
  end

  describe '#read_plain_lines' do
    let(:path) { ::File.join('spec', 'fixtures', 'helloworld.log') }

    it 'reads plain files' do
      expected = [["hello\n", 1], ["world\n", 2]]

      out = []
      LogStash::Inputs::CloudStorage::FileReader.read_plain_lines(path) do |text, linenum|
        out << [text, linenum]
      end

      expect(out).to eq(expected)
    end
  end

  describe '#read_gzip_lines' do
    let(:path) { ::File.join('spec', 'fixtures', 'helloworld.log.gz') }

    it 'reads gzipped files' do
      expected = [["hello\n", 1], ["world\n", 2]]

      out = []
      LogStash::Inputs::CloudStorage::FileReader.read_gzip_lines(path) do |text, linenum|
        out << [text, linenum]
      end

      expect(out).to eq(expected)
    end
  end
end

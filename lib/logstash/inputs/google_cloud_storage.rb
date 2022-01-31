# encoding: utf-8

require 'logstash/inputs/base'
require 'logstash/namespace'
require 'stud/interval'
require 'logstash/inputs/cloud_storage/client'
require 'logstash/inputs/cloud_storage/processed_db'
require 'logstash/inputs/cloud_storage/blob_filter'
require 'logstash/inputs/cloud_storage/file_reader'

# GoogleCloudStorage is an input plugin for Logstash that
# reads blobs in Cloud Storage buckets.
class LogStash::Inputs::GoogleCloudStorage < LogStash::Inputs::Base
  config_name 'google_cloud_storage'

  default :codec, 'plain'

  # Connection Settings
  config :bucket_id, :validate => :string, :required => true
  config :json_key_file, :validate => :string, :default => ''
  config :interval, :validate => :number, :default => 60

  # Inclusion/Exclusion Criteria
  config :blob_prefix, :validate => :string, :default => ''
  config :file_matches, :validate => :string, :default => '.*\\.log(\\.gz)?'
  config :file_exclude, :validate => :string, :default => '^$'
  config :metadata_key, :validate => :string, :default => 'x-goog-meta-ls-gcs-input'
  config :processed_db_path, :validate => :string, :default => nil

  config :delete, :validate => :boolean, :default => false
  config :unpack_gzip, :validate => :boolean, :default => true

  # Other Criteria
  config :temp_directory, :validate => :string, :default => File.join(Dir.tmpdir, 'ls-in-gcs')

  # Accessors for testing
  attr_accessor :event_output_queue
  attr_reader :processed_db

  def register
    FileUtils.mkdir_p(@temp_directory) unless Dir.exist?(@temp_directory)

    @client = LogStash::Inputs::CloudStorage::Client.new(@bucket_id, @blob_prefix, @json_key_file, @logger)

    if @processed_db_path.nil?
      ls_data = LogStash::SETTINGS.get_value('path.data')
      @processed_db_path = File.join(ls_data, 'plugins', 'inputs', 'google_cloud_storage', 'db')
    end

    @logger.info("ProcessedDb created in: #{@processed_db_path}")

    @processed_db = LogStash::Inputs::CloudStorage::ProcessedDb.new(@processed_db_path)

    @blob_filter = LogStash::Inputs::CloudStorage::BlobFilter.new(@logger, @file_matches, @file_exclude, @metadata_key, @processed_db)
  end

  def run(queue)
    @event_output_queue = queue

    @main_plugin_thread = Thread.current
    Stud.interval(@interval) do
      list_download_process
    end
  end

  # Fetches new files ready to be processed, downloads and processes them and finally
  # runs post-processing steps.
  def list_download_process
    list_processable_blobs do |blob|
      @logger.info("Found matching blob #{blob.uri}")
      download_and_process(blob)
      postprocess(blob)
    end
  end

  def stop
    # Stud events were started on the main plugin thread so stop all events relative to it.
    Stud.stop!(@main_plugin_thread)
  end

  private

  # list_processable_blobs will list blobs in the bucket and yield them if they are not filtered
  def list_processable_blobs
    @logger.info("Fetching blobs from #{@bucket_id}/#{@blob_prefix}")
    @client.list_blobs do |blob|
      yield blob if @blob_filter.should_process?(blob)
    end
  end

  def download_and_process(blob)
    @logger.info("Downloading blob #{blob.uri}")

    blob.with_downloaded(@temp_directory) do |path|
      @logger.info("Reading events from #{blob.uri} (temp file: #{path})")

      LogStash::Inputs::CloudStorage::FileReader.read_lines(path, @unpack_gzip) do |line, num|
        extract_event(line, num, blob)
      end
    end
  end

  def postprocess(blob)
    blob.set_metadata!(@metadata_key, 'processed') unless @metadata_key.empty?

    blob.delete! if @delete

    @processed_db.mark_processed(blob) unless @processed_db_path.empty?
  end

  def extract_event(line, line_num, blob)
    @codec.decode(line) do |event|
      decorate(event)
      event.set('[@metadata][gcs]', blob.line_attributes(line_num))
      @event_output_queue << event
    end
  end
end

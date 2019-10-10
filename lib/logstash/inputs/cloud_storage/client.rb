# encoding: utf-8

require 'thread'
require 'java'
require 'logstash-input-google_cloud_storage_jars.rb'
require 'logstash/inputs/cloud_storage/blob_adapter'

module LogStash
  module Inputs
    module CloudStorage
      # Client provides all the required transport and authentication setup for the plugin.
      class Client
        def initialize(bucket, json_key_path, logger, blob_prefix='')
          @logger = logger
          @bucket = bucket
          @blob_prefix = blob_prefix

          # create client
          @storage = initialize_storage json_key_path
        end

        java_import 'com.google.cloud.storage.Storage'
        def list_blobs
          # NOTE: there is the option to filter which fields are returned by
          # the call. If we find the bandwidth overhead is too much it would be
          # possible (but tedious) to filter the returned fields to just those
          # that this plugin uses.
          filter = []
          if @blob_prefix != ''
            filter = [Storage::BlobListOption.prefix(@blob_prefix)]
          end

          @storage.list(@bucket, filter.to_java).iterateAll().each do |blobname|
            yield LogStash::Inputs::CloudStorage::BlobAdapter.new(blobname)
          end
        rescue Java::ComGoogleCloudStorage::StorageException => e
          raise "Error listing bucket contents: #{e}"
        end

        private

        def initialize_storage(json_key_path)
          com.google.cloud.storage.StorageOptions.newBuilder()
             .setCredentials(credentials(json_key_path))
             .setHeaderProvider(http_headers)
             .setRetrySettings(retry_settings)
             .build()
             .getService()
        end

        java_import 'com.google.auth.oauth2.GoogleCredentials'
        def credentials(json_key_path)
          return GoogleCredentials.getApplicationDefault() if json_key_path.empty?

          key_file = java.io.FileInputStream.new(json_key_path)
          GoogleCredentials.fromStream(key_file)
        end

        java_import 'com.google.api.gax.rpc.FixedHeaderProvider'
        def http_headers
          gem_name = 'logstash-input-google_cloud_storage'
          gem_version = '1.0.0'
          user_agent = "Elastic/#{gem_name} version/#{gem_version}"

          FixedHeaderProvider.create({ 'User-Agent' => user_agent })
        end

        java_import 'com.google.api.gax.retrying.RetrySettings'
        java_import 'org.threeten.bp.Duration'
        def retry_settings
          # backoff values taken from com.google.api.client.util.ExponentialBackOff
          RetrySettings.newBuilder()
                       .setInitialRetryDelay(Duration.ofMillis(500))
                       .setRetryDelayMultiplier(1.5)
                       .setMaxRetryDelay(Duration.ofSeconds(60))
                       .setInitialRpcTimeout(Duration.ofSeconds(20))
                       .setRpcTimeoutMultiplier(1.5)
                       .setMaxRpcTimeout(Duration.ofSeconds(20))
                       .setTotalTimeout(Duration.ofMinutes(15))
                       .build()
        end
      end
    end
  end
end

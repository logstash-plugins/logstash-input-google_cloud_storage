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
        def initialize(bucket, json_key_path, logger)
          @logger = logger
          @bucket = bucket

          # create client
          @storage = initialize_storage json_key_path
        end

        def list_blobs
          @storage.list(@bucket).iterateAll().each do |blobname|
            yield LogStash::Inputs::CloudStorage::BlobAdapter.new(blobname)
          end
        rescue Java::ComGoogleCloudStorage::StorageException => e
          raise "Error listing bucket contents: #{e}"
        end

        private
        
        java_import 'com.google.auth.oauth2.GoogleCredentials'
        def initialize_storage(json_key_path)
          # initialize the StorageOptions builder
          builder = com.google.cloud.storage.StorageOptions.newBuilder()

          # initialize it normally if a json_key_path is provided
          if !json_key_path.empty?
            key_file = java.io.FileInputStream.new(json_key_path)
            builder.setCredentials(GoogleCredentials.fromStream(key_file))
          else
            # if a json_key_path is not provided, try using the getApplicationDefault, normally 
            # using GOOGLE_APPLICATION_CREDENTIALS env variable 
            begin
              builder.setCredentials(GoogleCredentials.getApplicationDefault())
            rescue Java::JavaIo::IOException => e
              # an IOException is generated if no default credentials exist, trying unauthenticated
              builder = com.google.cloud.storage.StorageOptions.getUnauthenticatedInstance()
              .toBuilder()
            end
          end
          builder.setHeaderProvider(http_headers)
              .setRetrySettings(retry_settings)
              .build()
              .getService()
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

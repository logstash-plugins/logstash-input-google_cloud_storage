# encoding: utf-8

module LogStash
  module Inputs
    module CloudStorage
      # BlobFilter acts as a .filter for BlobAdapters.
      class BlobFilter
        # Initialize the filter.
        # Throws an exception if the regular expressions could not compile.
        def initialize(logger, include_regex, exclude_regex, metadata_key, processed_db)
          @logger = logger
          @include_regex = compile_regex(include_regex)
          @exclude_regex = compile_regex(exclude_regex)
          @metadata_key = metadata_key
          @processed_db = processed_db

          @logger.info('Turn on debugging to explain why blobs are filtered.')
        end

        # should_process? returns true if the blob matches all the
        # user-provided requirements to download and extract events.
        def should_process?(blob)
          @logger.debug("Found blob: #{blob.name}")

          # Evaluate all conditions because the operations are cheap and give the
          # user a complete idea of why a blob was included/excluded.
          conditions = [
            not_already_run?(blob),
            included?(blob),
            not_excluded?(blob),
            metadata_does_not_exist?(blob)
          ]

          conditions.all?
        end

        private

        def compile_regex(regex)
          Regexp.new(regex)
        rescue StandardError => e
          raise "Could not compile regex '#{regex}': #{e}"
        end

        def not_already_run?(blob)
          result = @processed_db.nil? || !@processed_db.already_processed?(blob)

          explain('Not included in ProcessedDB', result)
        end

        def included?(blob)
          explain('Matches include regex', name_matches(blob.name, @include_regex))
        end

        def not_excluded?(blob)
          explain('Does not match exclude regex', !name_matches(blob.name, @exclude_regex))
        end

        def metadata_does_not_exist?(blob)
          # an empty key means the user doesn't want to store/check the metadata
          return true if @metadata_key.empty?

          has_key = !blob.metadata.nil? && blob.metadata.key?(@metadata_key)

          explain('Does not have metadata key', !has_key)
        end

        def explain(message, result)
          pf = result ? 'pass' : 'fail'

          @logger.debug(" - #{message}? (#{pf})")

          result
        end

        def name_matches(name, regex)
          match = regex.match(name)
          return false if match.nil?

          match.pre_match.empty? && match.post_match.empty?
        end
      end
    end
  end
end

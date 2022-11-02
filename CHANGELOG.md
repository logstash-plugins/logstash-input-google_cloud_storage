## 0.13.0
 - Updated Google Cloud Storage client library, from `1.118.1` to `2.12.0` [#21](https://github.com/logstash-plugins/logstash-output-google_cloud_storage/pull/21)

## 0.12.0
 - Updated Google Cloud Storage client library, needs Logstash `>= 8.3.0` to run [#20](https://github.com/logstash-plugins/logstash-input-google_cloud_storage/pull/20)

## 0.11.0

- Change gzip file detection to use mime type instead of extension

## 0.10.0

- Updated JAR dependencies.
- Changed the way lines were being read to not strip the included line endings.

## 0.9.0

- Initial release
- File inclusion/exclusion by 
  - regex
  - processed database
  - metadata key
- Authenticate using Application Default Credentials or JSON keys
- Read GZipped files

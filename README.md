# Logstash Input Google Cloud Storage

Extracts events from files in a Google Cloud Storage bucket.

Example use-cases:

 * Read [Stackdriver logs](https://cloud.google.com/stackdriver/) from a Cloud Storage bucket into Elastic.
 * Read gzipped logs from cold-storage into Elastic.
 * Restore data from an Elastic dump.
 * Extract data from Cloud Storage, transform it with Logstash and load it into BigQuery.

Note: While this project is partially maintained by Google, this is not an official Google product.

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

Logstash provides infrastructure to automatically generate documentation for this plugin. We use the asciidoc format to write documentation so any comments in the source code will be first converted into asciidoc and then into html. All plugin documentation are placed under one [central location](http://www.elastic.co/guide/en/logstash/current/).

- For formatting code or config example, you can use the asciidoc `[source,ruby]` directive
- For more asciidoc formatting tips, see the excellent reference here https://github.com/elastic/docs#asciidoc-guide

## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Plugin Development and Testing

#### Code

- To get started, you'll need JRuby with the Bundler gem installed.
- You'll also need a Logstash installation to build the plugin against.

- Create a new plugin or clone and existing from the GitHub [logstash-plugins](https://github.com/logstash-plugins) organization. We also provide [example plugins](https://github.com/logstash-plugins?query=example).
- `export LOGSTASH_SOURCE=1` and point `LOGSTASH_PATH` to a local Logstash
  e.g. `export LOGSTASH_PATH=/opt/local/logstash-8.7.0`

- Install Ruby dependencies
```sh
bundle install
```

- Install Java dependencies - regenerates the *lib/logstash-input-google_cloud_storage_jars.rb*
  script used to load the .jar dependencies when the plugin starts.
```sh
./gradlew vendor
```
  NOTE: This step is necessary whenever **build.gradle** is updated.

#### Test

- Update your dependencies

```sh
bundle install
```

- Run Ruby tests

```sh
bundle exec rspec
```

### 2. Running your unpublished Plugin in Logstash

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-input-google_cloud_storage", :path => "/your/local/logstash-input-google_cloud_storage"
```
- Install plugin
```sh
bin/logstash-plugin install --no-verify logstash-input-google_cloud_storage
```
- Run Logstash with your plugin
```sh
bin/logstash -e 'input {google_cloud_storage {}}'
```
At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-input-google_cloud_storage.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/logstash-plugin install /your/local/plugin/logstash-input-google_cloud_storage.gem
```
- Start Logstash and proceed to test the plugin

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.

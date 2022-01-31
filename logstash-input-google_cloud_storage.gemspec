Gem::Specification.new do |s|
  s.name          = 'logstash-input-google_cloud_storage'
  s.version       = '0.12.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Plugin to import log data from Google Cloud Storage (GCS).'
  s.description   = 'This gem is a Logstash plugin required to be installed on top of the '\
                    'Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. '\
                    'This gem is not a stand-alone program'
  s.homepage      = 'http://www.elastic.co/guide/en/logstash/current/index.html'
  s.authors       = ['Elastic', 'Joseph Lewis III']
  s.email         = 'info@elastic.co'
  s.require_paths = ['lib', 'vendor/jar-dependencies']

  # Files
  s.files = Dir[
      # Code
      'lib/**/*',
      'spec/**/*',
      'vendor/**/*',
      'vendor/jar-dependencies/**/*.jar',
      'vendor/jar-dependencies/**/*.rb',
      # Library
      'Gemfile',
      '*.gemspec',
      # Documentation
      '*.md',
      'CONTRIBUTORS',
      'LICENSE',
      'NOTICE.TXT',
      'VERSION',
      'docs/**/*']

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'input' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'logstash-core-plugin-api', '~> 2.0'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  s.add_runtime_dependency 'mimemagic', '>= 0.3.3'

  s.add_development_dependency 'logstash-devutils', '>= 1.0.0'

  # Java
  s.add_development_dependency 'jar-dependencies', '~> 0.3.4'
  s.platform = 'java'
end

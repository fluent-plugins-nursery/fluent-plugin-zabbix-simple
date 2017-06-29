# -*- encoding: utf-8 -*-
# -*- mode:ruby -*-

Gem::Specification.new do |gem|
  gem.authors       = ["NAKANO Hideo"]
  gem.email         = ["nakano@ilu.co.jp"]
  gem.description   = %q{Output data plugin to Zabbix}
  gem.summary       = %q{Output data plugin to Zabbix (like zabbix_sender)}
  gem.homepage      = "https://github.com/sunny4381/fluent-plugin-zabbix-simple"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-zabbix-simple"
  gem.require_paths = ["lib"]
  gem.version       = "1.0.0"

  gem.add_development_dependency "bundler"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit", "~> 3.2.0"
  gem.add_runtime_dependency "fluentd", [">= 0.14.15", "< 2"]
  gem.add_runtime_dependency "zabbix"
end

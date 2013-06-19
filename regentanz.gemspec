# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "regentanz/version"

Gem::Specification.new do |s|
  s.name        = "regentanz"
  s.version     = Regentanz::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Carsten Zimmermann"]
  s.email       = ["cz@aegisnet.de"]
  s.homepage    = ""
  s.summary     = %q{Library to access the Google Weather API}
  s.description = %q{Library to access the Google Weather API}

  s.rubyforge_project = "regentanz"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport', '~> 3.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'factory_girl', '~> 2.0'
  s.add_development_dependency 'rdoc', '~> 2.4'
  s.add_development_dependency 'rspec'

end

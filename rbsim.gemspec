# Used this istruction to create the gem:
# http://guides.rubygems.org/make-your-own-gem/
# some things below were based on docile gem.

$:.push File.expand_path('../lib', __FILE__)
require 'rbsim/version'

Gem::Specification.new do |s|
  s.name = 'rbsim'
  s.version = RBSim::VERSION
  s.authors = ['Wojciech Rząsa']
  s.email = %w(wrzasa@prz-rzeszow.pl)
  s.homepage = 'http://wrzasa.sd.prz.edu.pl/'
  s.summary = 'Distributed inftastructure and system simulator with convenient DSL.'
  s.description = 'You can model your distributed infrastructora and application and simulate its behavior and observe its efficiency easily.'
  s.license = '(c) WRz'

  s.platform = 'ruby'
  s.required_ruby_version = '~> 2.0'

#  s.rubyforge_project = ''

  s.files = `hg locate`.split("\n")
  s.test_files = `hg locate spec/*`.split("\n")
  s.executables = `hg locate -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.add_runtime_dependency 'docile', '~> 1.1'
  s.add_runtime_dependency 'fast-tcpn', '~> 0'

  # Running rspec tests from rake
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rspec-its', '~> 1.0'
  s.add_development_dependency 'simplecov', '~> 0'

  s.extra_rdoc_files << 'README.md'
  s.rdoc_options << '--main' << 'README.md'
  s.rdoc_options << '--title' << 'RBSim -- Distributed system modeling and simulation tool'
  s.rdoc_options << '--line-numbers'
  s.rdoc_options << '-A'
  s.rdoc_options << '-x coverage'
end

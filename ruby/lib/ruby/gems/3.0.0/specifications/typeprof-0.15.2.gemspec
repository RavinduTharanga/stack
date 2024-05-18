# -*- encoding: utf-8 -*-
# stub: typeprof 0.15.2 ruby lib

Gem::Specification.new do |s|
  s.name = "typeprof".freeze
  s.version = "0.15.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/ruby/typeprof", "source_code_uri" => "https://github.com/ruby/typeprof" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yusuke Endoh".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-08-18"
  s.description = "TypeProf performs a type analysis of non-annotated Ruby code.\n\nIt abstractly executes input Ruby code in a level of types instead of values, gathers what types are passed to and returned by methods, and prints the analysis result in RBS format, a standard type description format for Ruby 3.0.\n\nThis tool is planned to be bundled with Ruby 3.0.\n".freeze
  s.email = ["mame@ruby-lang.org".freeze]
  s.executables = ["typeprof".freeze]
  s.files = ["exe/typeprof".freeze]
  s.homepage = "https://github.com/ruby/typeprof".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.2.33".freeze
  s.summary = "TypeProf is a type analysis tool for Ruby code based on abstract interpretation".freeze

  s.installed_by_version = "3.2.33" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rbs>.freeze, [">= 1.3.1"])
  else
    s.add_dependency(%q<rbs>.freeze, [">= 1.3.1"])
  end
end

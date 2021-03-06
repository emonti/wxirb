# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wxirb}
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Monti"]
  s.date = %q{2009-06-17}
  s.default_executable = %q{wxirb}
  s.description = %q{A wxwidgets-based IRB-like ruby console}
  s.email = %q{emonti@matasano.com}
  s.executables = ["wxirb"]
  s.extra_rdoc_files = ["History.txt", "README.rdoc", "bin/wxirb"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "bin/wxirb", "lib/wxirb.rb", "screenshots/screenshot.png", "screenshots/who_is_your_daddy.png", "tasks/ann.rake", "tasks/bones.rake", "tasks/gem.rake", "tasks/git.rake", "tasks/notes.rake", "tasks/post_load.rake", "tasks/rdoc.rake", "tasks/rubyforge.rake", "tasks/setup.rb", "tasks/spec.rake", "tasks/svn.rake", "tasks/test.rake", "wxirb.gemspec"]
  s.homepage = %q{http://www.github.com/emonti/wxirb}
  s.rdoc_options = ["--line-numbers", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{wxirb}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A wxwidgets-based IRB-like ruby console}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<wxruby>, [">= 2.0.0"])
      s.add_development_dependency(%q<bones>, [">= 2.5.1"])
    else
      s.add_dependency(%q<wxruby>, [">= 2.0.0"])
      s.add_dependency(%q<bones>, [">= 2.5.1"])
    end
  else
    s.add_dependency(%q<wxruby>, [">= 2.0.0"])
    s.add_dependency(%q<bones>, [">= 2.5.1"])
  end
end

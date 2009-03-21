# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{wxirb}
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Monti"]
  s.date = %q{2009-03-20}
  s.default_executable = %q{wxirb}
  s.description = %q{A wxwidgets-based IRB-like ruby console}
  s.email = %q{emonti@matasano.com}
  s.executables = ["wxirb"]
  s.extra_rdoc_files = ["History.txt", "README.rdoc", "bin/wxirb"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "bin/wxirb", "lib/wxirb.rb", "screenshots/screenshot.png", "screenshots/who_is_your_daddy.png", "tasks/ann.rake", "tasks/bones.rake", "tasks/gem.rake", "tasks/git.rake", "tasks/notes.rake", "tasks/post_load.rake", "tasks/rdoc.rake", "tasks/rubyforge.rake", "tasks/setup.rb", "tasks/spec.rake", "tasks/svn.rake", "tasks/test.rake", "wxirb.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{www.gitshed.com/emonti/wxirb}
  s.rdoc_options = ["--line-numbers", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ }
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A wxwidgets-based IRB-like ruby console}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<wxruby>, [">= 2.0.0"])
      s.add_development_dependency(%q<bones>, [">= 2.4.2"])
    else
      s.add_dependency(%q<wxruby>, [">= 2.0.0"])
      s.add_dependency(%q<bones>, [">= 2.4.2"])
    end
  else
    s.add_dependency(%q<wxruby>, [">= 2.0.0"])
    s.add_dependency(%q<bones>, [">= 2.4.2"])
  end
end

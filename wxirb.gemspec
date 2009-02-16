require 'rubygems'
SPEC = Gem::Specification.new do |s|
  s.name      = "wxirb"
  s.version   = "1.0.0"
  s.author    = "Eric Monti"
  s.email     = "emonti@matasano.com"
  s.homepage  = "http://www.matasano.com"
  s.platform  = Gem::Platform::RUBY
  s.summary   = "A GUI IRB-like console based on WxRuby"

  s.files = ["README.rdoc", "bin/wxirb", "lib/wxirb.rb"]

  s.require_path      = "lib"
  s.autorequire       = "wxirb"

  s.default_executable  = "wxirb"
  s.executables         = ["wxirb"]

  s.has_rdoc          = true
  s.extra_rdoc_files  = ["README.rdoc"]

  s.add_dependency("wxruby", ">= 1.9.9")
end


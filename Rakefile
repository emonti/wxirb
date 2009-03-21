# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'wxirb'

task :default => 'test:run'

PROJ.name = 'wxirb'
PROJ.authors = 'Eric Monti'
PROJ.email = 'emonti@matasano.com'
PROJ.description = 'A wxwidgets-based IRB-like ruby console'
PROJ.url = 'www.gitshed.com/emonti/wxirb'
PROJ.version = WxIRB::VERSION
#PROJ.rubyforge.name = 'wxirb'
PROJ.readme_file = 'README.rdoc'

PROJ.spec.opts << '--color'

PROJ.rdoc.opts << '--line-numbers'

#PROJ.rdoc.opts << '--diagram'
PROJ.notes.tags << "X"+"XX" # muhah! so we don't note our-self

# exclude rcov.rb and external libs from rcov report
PROJ.rcov.opts += ["--exclude",  "rcov.rb", "--exclude", "wxruby"]

depend_on 'wxruby', '>= 2.0.0'

# EOF

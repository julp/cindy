module Cindy
end

load_dir = Pathname.new(__FILE__).dirname

load load_dir.join('cindy/version.rb')
load load_dir.join('cindy/cindy.rb')
load load_dir.join('cindy/command.rb')
load load_dir.join('cindy/environment.rb')
load load_dir.join('cindy/variable.rb')
load load_dir.join('cindy/template.rb')

load load_dir.join('cindy/executor/ssh.rb')
load load_dir.join('cindy/executor/local.rb')

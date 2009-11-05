require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/backs3'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'backs3' do
  self.developer 'Jeremy Wells', 'jeremy@boost.co.nz'
  self.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  self.description = "S3 backup and restore program"
  #self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [['activesupport','>= 2.0.2'], ['aws-s3', '>= 0.5.1']]
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]

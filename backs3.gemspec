# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{backs3}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Wells"]
  s.date = %q{2009-03-25}
  s.description = %q{S3 backup and restore program}
  s.email = ["jeremy@boost.co.nz"]
  s.executables = ["backs3", "res3"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "example.conf", "bin/backs3", "bin/res3", "lib/backs3.rb", "lib/backs3/backs3.rb", "lib/backs3/backup.rb", "lib/backs3/restore.rb", "lib/backs3/version.rb", "spec/spec.opts", "spec/spec_helper.rb", "spec/backs3/backup_spec.rb", "spec/backs3/restore_spec.rb", "tasks/rspec.rake"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/jemmyw/backs3}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{backs3}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{S3 backup and restore program}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_runtime_dependency(%q<aws-s3>, [">= 0.5.1"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_dependency(%q<aws-s3>, [">= 0.5.1"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.0.2"])
    s.add_dependency(%q<aws-s3>, [">= 0.5.1"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end

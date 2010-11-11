task :default => ['doc:all']

namespace :doc do

  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
  rescue LoadError
    abort "Please install the YARD gem to generate rdoc."
  end

  root = File.dirname(__FILE__)
  dest = File.join(root, 'doc', 'rdoc')

  desc 'Copy media for documentation'
  task :media do
    cp './poodle.jpg', './doc/rdoc/'
  end

  desc 'Generate overview documentation'
  YARD::Rake::YardocTask.new(:overview) do |yt|
    yt.files   = []
    yt.options = ['--output-dir', dest, '-', 'VERSION.md', 'CHANGES.md']
  end

  desc 'Generate *all* api documentation'
  task :yard do
      FileList["*/**/Rakefile"].each do |rakefile|
          Dir.chdir(rakefile.pathmap("%d")) do
            system 'rake doc:yard'
          end
      end
  end

  desc 'Generate *all* documentation'
  task :all => [:overview, :yard, :media] do
  end

end

namespace :install do
  desc 'Fetch all required gems, bundler must be installed' # CHECK and assert???
  task :all do
      FileList["./**/Gemfile"].each do |gem|
          Dir.chdir(gem.pathmap("%d")) do
            system 'bundle install'
          end
      end
  end
end

desc 'Run *all* tests'
task :test do
  FileList["*/**/Rakefile"].each do |rakefile|
    Dir.chdir(rakefile.pathmap("%d")) do
    system 'rake test'
    end
  end
end

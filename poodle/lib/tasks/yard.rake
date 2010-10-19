require 'yard'
require 'yard/rake/yardoc_task'
  
namespace :doc do
  YARD::Rake::YardocTask.new(:yard) do |yt|
    yt.files   = Dir.glob(File.join('.', '**', '*.rb'))
    yt.options = ['--output-dir', '../doc/rdoc/poodle', '--readme', './doc/README_FOR_APP.md']
  end
end

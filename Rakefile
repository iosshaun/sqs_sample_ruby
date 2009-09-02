require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/aws/sqs'

task :default => :test

Rake::TestTask.new do |test|
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

namespace :dist do
  spec = Gem::Specification.new do |s|
    s.name = 'aws-sqs'
    s.version = Gem::Version.new(AWS::SQS::Version)
    s.summary = "Client library for Amazon's Simple Queue Service"
    s.description = s.summary
    s.email = 'joshua.go@refinition.net'
    s.author = "Joshua Go"
    s.has_rdoc = true
    s.extra_rdoc_files = %w(README COPYING INSTALL)
    s.homepage = 'http://refinition.net/aws-sqs'
    s.files = FileList['Rakefile', 'lib/**/*.rb']
  end

  task :package => 'doc:readme'
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar_gz = true
    pkg.package_files.include('{lib,test}/**/*')
    pkg.package_files.include('README')
    pkg.package_files.include('COPYING')
    pkg.package_files.include('INSTALL')
    pkg.package_files.include('Rakefile')
  end

  desc 'Install with gems'
  task :install => :repackage do
    sh "sudo gem -i pkg/#{spec.name}-#{spec.version}.gem"
  end

  desc 'Uninstall gem'
  task :uninstall do
    sh "sudo gem uninstall #{spec.name} -x"
  end

  desc 'Reinstall gem'
  task :reinstall => [:uninstall, :install]
end

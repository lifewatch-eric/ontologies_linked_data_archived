source 'https://rubygems.org'

gem 'rake', '~> 10.0'
gem 'rack', '~> 1.0'
gem 'rack-test', '~> 0.6'
gem 'activesupport', '~> 4.0'
gem 'rubyzip', '~> 1.0'
gem 'bcrypt-ruby', '~> 3.0'
gem 'multi_json', '~> 1.0'
gem 'oj', '~> 2.0'
gem 'libxml-ruby', '~> 2.0'
gem 'rsolr', '~> 1.0'
gem 'minitest', '~> 4.0'
gem 'cube-ruby', require: "cube"

# Testing
gem 'simplecov', :group => :test
gem 'pry', :group => :test

# NCBO gems (can be from a local dev path or from rubygems/git)
ncbo_branch = ENV["NCBO_BRANCH"] || `git rev-parse --abbrev-ref HEAD`.strip || "staging"
gem 'goo', github: 'ncbo/goo', branch: ncbo_branch
gem 'sparql-client', github: 'ncbo/sparql-client', branch: ncbo_branch

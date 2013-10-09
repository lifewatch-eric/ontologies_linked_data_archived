source 'https://rubygems.org'

gem 'rake'
gem 'rack'
gem 'rack-test'
gem 'activesupport'
gem 'pry'
gem 'rubyzip'
gem 'bcrypt-ruby'
gem 'multi_json'
gem 'oj'
gem 'libxml-ruby'
gem 'rsolr'
gem 'minitest', '< 5.0'
gem 'cube-ruby', require: "cube"

# Testing
gem 'simplecov', :require => false, :group => :test


# NCBO gems (can be from a local dev path or from rubygems/git)
ncbo_branch = ENV["NCBO_BRANCH"] || `git rev-parse --abbrev-ref HEAD` || "staging"

source :rubygems

gem 'rake'
gem 'rack'
gem 'rack-test'
gem 'activesupport'
gem 'pry'
gem 'rubyzip'
gem 'bcrypt-ruby'
gem 'multi_json'
gem 'oj'
gem 'libxml-ruby', '>= 2.7.0'
gem 'rsolr'
gem 'minitest', '< 5.0'
gem 'cube-ruby', require: "cube"

# Testing
gem 'simplecov', :require => false, :group => :test


# NCBO gems (can be from a local dev path or from rubygems/git)
gemfile_local = File.expand_path("../Gemfile.local", __FILE__)
if File.exists?(gemfile_local)
  self.instance_eval(Bundler.read_file(gemfile_local))
else
  gem 'goo', :git => 'https://github.com/ncbo/goo.git'
  gem 'sparql-client', :git => 'https://github.com/ncbo/sparql-client.git'
end

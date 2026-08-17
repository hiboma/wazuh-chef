source 'https://rubygems.org'

#group :lint do
#    gem 'rubocop'
#    gem 'yaml-lint'
#    gem 'mdl'
#end

group :kitchen do
    gem 'test-kitchen'
    gem 'kitchen-inspec'
    # inspec-core 6.x and later require a Progress Chef license key at runtime
    # when InSpec detects it is running under Test Kitchen, which makes
    # `kitchen verify` fail with "Chef Workstation cannot execute without
    # valid licenses" (exit 174). 5.24.24 is the last release without the
    # chef-licensing dependency.
    gem 'inspec-core', '= 5.24.24'
end

gem 'berkshelf'
gem 'chef', '~> 18.0'

group :dokken do
    gem 'kitchen-dokken'
end

group :vagrant do
    gem 'kitchen-vagrant'
end
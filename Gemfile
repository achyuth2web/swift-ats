source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "rails", "~> 7.1.0"
gem "pg", "~> 1.1"
gem "puma", "~> 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "sprockets-rails"
gem "jbuilder"
gem "devise"
gem "dotenv-rails"
gem "pdf-reader"
gem "docx"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
gem "discard"
gem 'kaminari'
gem 'roo'

# AWS Gem
gem 'aws-sdk-s3'

# Google Oauth
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem "web-console"
end

group :production do
  gem "rails_12factor"
end

# frozen_string_literal: true

require 'bundler/setup'
require 'shotgun_api_ruby'
require 'simplecov'
require 'rspec_in_context'
require 'faker'
require 'timecop'
require 'vcr'

require 'dotenv/load'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :faraday
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
  config.filter_sensitive_data('<SCRIPT_NAME>') do
    ENV['VCR_SHOTGUN_SCRIPT_NAME'] || 'vcr_shotgun_script_name'
  end
  config.filter_sensitive_data('<SCRIPT_KEY>') do
    ENV['VCR_SHOTGUN_SCRIPT_KEY'] || 'vcr_shotgun_script_key'
  end
  # config.before_record do |i|
  #   i.response.body.sub!(
  #     /access_token":"[^"]+"/,
  #     "access_token\":\"<ACCESS_TOKEN>\"",
  #   )
  #   i.request.headers['Authorization'] = '<ACCESS_TOKEN>' if i.request.headers[
  #     'Authorization'
  #   ]
  #   i.request.uri.sub!(
  #     ENV['VCR_FORGE_API_BASE_URL'],
  #     'http://vcr.forge.api.url',
  #   )
  # end
end

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter]

SimpleCov.at_exit do
  SimpleCov.result.format!
  SimpleCov.minimum_coverage 90
  SimpleCov.minimum_coverage_by_file 80
end

SimpleCov.start do
  load_profile 'test_frameworks'
  add_filter { |source_file| source_file.lines.count < 5 }
end

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }
RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  config.include RspecInContext

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
end

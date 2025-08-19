require 'simplecov'
SimpleCov.start 'rails' do
  enable_coverage :branch
  add_filter %w[ bin/ db/ config/ spec/ vendor/ tmp/ ]

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Jobs', 'app/jobs'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Channels', 'app/channels'
  add_group 'Libraries', 'lib'
  add_group 'Views', 'app/views'
end

# 最小カバレッジ（現状を下回らないゆるめ値）
SimpleCov.minimum_coverage 60
SimpleCov.refuse_coverage_drop if ENV['CI']

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.example_status_persistence_file_path = "spec/examples.txt"
  config.order = :random
  Kernel.srand config.seed
end

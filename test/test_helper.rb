ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Fixtures de la app y de cada pack (packs/*/test/fixtures).
    self.fixture_paths += Dir[Rails.root.join("packs/*/test/fixtures")]
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

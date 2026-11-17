ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# `bin/rails test` corre también los tests de cada pack (packs/*/test).
# packs-rails no trae integración con Minitest; ver docs/decisions/0001.
ENV["DEFAULT_TEST"] ||= "{test,packs/*/test}/**/*_test.rb"
ENV["DEFAULT_TEST_EXCLUDE"] ||= "{test,packs/*/test}/{system,dummy,fixtures}/**/*_test.rb"

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

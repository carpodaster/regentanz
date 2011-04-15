require "rubygems"
require "bundler/setup"

require "test/unit"
require "active_support/test_case"
require 'action_mailer/test_helper'
Bundler.require(:default, :development)
require 'test/factories'

# FIXME move SupportMailer into callbacks
require File.join(File.dirname(__FILE__), 'support', 'support_mailer')

# Configure for test mode
Regentanz.configure do |config|
  config.do_not_get_weather = true
  config.suppress_stderr_output = true
  config.cache_dir    = File.expand_path(File.join(File.dirname(__FILE__), 'support', 'tmp'))
  config.retry_marker = File.expand_path(File.join(File.dirname(__FILE__), 'support', 'tmp', 'test_api_retry.txt'))
end

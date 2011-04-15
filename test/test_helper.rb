require "rubygems"
require "bundler/setup"

# FIXME remove Rails dependency (should be Rails.root anyway).
RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), 'support'))

puts "Fake Rails.root is `#{RAILS_ROOT}`"

require "test/unit"
require "active_support/test_case"
require 'action_mailer/test_helper'
Bundler.require(:default, :development)
require 'test/factories'

# FIXME move SupportMailer into proper configurable callbacks
require File.join(File.dirname(__FILE__), 'support', 'support_mailer')

# Mocha is unable to stub constants, so we hack around it a bit:
# http://www.danielcadenas.com/2008/09/stubbingmocking-constants-with-mocha.html
class Module #:nodoc:
  def redefine_const(name, value)
    __send__(:remove_const, name) if const_defined?(name)
    const_set(name, value)
  end
end


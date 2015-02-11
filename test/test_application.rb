# load the test_helper.rb file which is in the same directory
require_relative "test_helper"

# create a TestApp Class that inherits functionality from the Rulers Rack app
class TestApp < Rulers::Application
end

# a test app that inherits from test::unit::testcase so we can test it
class RulersAppTest < Test::Unit::TestCase
  # include testing methods specifially for the rack middleware
  include Rack::Test::Methods

  def app
    TestApp.new
  end

  def test_request
    get "/"
    assert last_response.ok?
    body = last_response.body
    assert body["Hello"]
  end

end
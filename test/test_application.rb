# load the test_helper.rb file which is in the same directory
require_relative "test_helper"


# creat a TestController
class TestController < Rulers::Controller
  def index
    "Hello" # not rendering a view!
  end
end

# create a TestApp Class that inherits functionality from the Rulers Rack app
class TestApp < Rulers::Application
  # override get_controller_and_action methdo
  def get_controller_and_action(env)
    # and hard-code values for controller class and -action
    [TestController, "index"]
  end
end

# a test app that inherits from test::unit::testcase so we can test it
class RulersAppTest < Test::Unit::TestCase
  # include testing methods specifially for the rack middleware
  include Rack::Test::Methods

  # The module Rack::Test::Methods serves as the primary integration point for using Rack::Test in a testing environment.
  # It depends on an app method being defined in the same context, and provides the Rack::Test API methods
  def app
    TestApp.new
  end

  # all methods available in that module are:
  # METHODS =
=begin
  [
      :request,
      :get,
      :post,
      :put,
      :patch,
      :delete,
      :options,
      :head,
      :follow_redirect!,
      :header,
      :env,
      :set_cookie,
      :clear_cookies,
      :authorize,
      :basic_authorize,
      :digest_authorize,
      :last_response,
      :last_request
  ]
=end

  def test_request
    get "/example/route"
    assert last_response.ok?
    body = last_response.body
    assert body["Hello"]
  end

end
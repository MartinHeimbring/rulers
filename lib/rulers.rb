# require the array file that contains an ActiveSupport-like useful method for interacting with arrays
require "rulers/array"
# require ruby version
require "rulers/version"
# require the routing.rb file
require "rulers/routing"

# this is our Framework
module Rulers
  # a rack app is an object that responds to "call"
  # so it can be either a lambda/proc or (like in our case)
  # a class with an instance method "call"
  class Application
    # we pass the call method incoming information from a request via the ENV hash
    def call(env)
      # quick & dirty hack to handle nonexistent favicon file
      if env['PATH_INFO'] == '/favicon.ico'
        return [404,{'Content-Type' => 'text/html'}, []]
      end
      # get_controller_and_action returns an array w/ two elements:
      # a controller name and an action name (both as strings)
      klass, act = get_controller_and_action(env)
      # instantiate the controller class whose name is inside the "klass" variable
      controller = klass.new(env)
      # call instance method of controller with name inside the "act" variable
      # and put returned value into "text" variable
      text = controller.send(act)
      # a rack app always return a "triplet" - made up of "status code", "headers" and "body"
      # display content of text variable in response body
      [200, {'Content-Type' => 'text/html'}, [text]]
    end
  end

  # other controllers will later inherit from Rulers::Controller
  class Controller
    # the controller just saves the environment that rack feed it
    def initialize(env)
      @env = env
    end

    # getter method for env
    def env
      @env
    end
  end
end
# require the array file that contains an ActiveSupport-like useful method for interacting with arrays
require "rulers/array"
require "rulers/version"
require "rulers/routing"
require "rulers/util"
require "rulers/dependencies"
require "rulers/controller"

# this is our Framework
module Rulers
  # a rack app is an object that responds to "call"
  # so it can be either a lambda/proc or (like in our case)
  # a class with an instance method "call"
  class Application
    # we pass the call method incoming information from a request via the ENV hash
    def call(env)
      # quick & dirty hack to handle nonexistent favicon file
      path_info = env['PATH_INFO']
      # handle requests to a path that is not specified as a custom controller/action
      case path_info
        # returning 404 not found
        when '/favicon.ico'
          return [404,{'Content-Type' => 'text/html'}, []]
        # set root route to return a welcome message
        when '/'
          return [200,{'Content-Type' => 'text/html'}, ['This is my homepage!']]
      end
      # otherwise simply proceed and instantiate the controller that is specified in the URL

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
end
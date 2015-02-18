# require the array file that contains an ActiveSupport-like useful method for interacting with arrays
require "rulers/array"
require "rulers/version"
require "rulers/routing"
require "rulers/util"
require "rulers/dependencies"
require "rulers/controller"
require "rulers/file_model"
require "rulers/view"

# this is our Framework
module Rulers
  # a rack app is an object that responds to "call"
  # so it can be either a lambda/proc or (like in our case)
  # a class with an instance method "call"
  class Application
    # we pass the call method incoming information from a request via the ENV hash
    def call(env)
      rack_app = get_rack_app(env)
      rack_app.call(env)
    end
  end
end

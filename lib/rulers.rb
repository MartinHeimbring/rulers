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

      # when I want to "manually" render a view template with variables that are accessible in the view I have to call ".render_responde" inside my controller
      # .render_response in return calls ".response", where we create and return a new instance of Rack::Response
      # thus if I call .get_response on my controller, I will get back a Rack::Response object
      if controller.get_response
        # constructing a response from the values inside the @response instance variable
        # Rack::Response has an instance method called .finnish that returns a response in a way that Rack expects it: [Status, Header, Response]
        # that method is aliased to ".to_a"
        # btw the method looks like:
=begin
        def finish(&block)
          @block = block

          if [204, 205, 304].include?(status.to_i)
            header.delete CONTENT_TYPE
            header.delete CONTENT_LENGTH
            close
            [status.to_i, header, []]
          else
            [status.to_i, header, BodyProxy.new(self){}]
          end
        end
        alias to_a finish           # For *response
=end
        # so let's recap: we get a Rack::Response object back (from calling .get_response) and call ".to_a" (".finish", respectively) on that object
        # we store status, header and response in variables
        st, hd, rs = controller.get_response.to_a
        # and return them inside an array, just like Rack expects us to
        # we flatten rs.body, in case the rs.body is a multi-dimensional array
        [st, hd, [rs.body].flatten]
      else
        # a rack app always return a "triplet" - made up of "status code", "headers" and "body"
        # display content of text variable in response body
        # this would be a default response:

        #[200,
        # {'Content-Type' => 'text/html'}, [text]]

        # but we are trying to implement Rails Automatic Rendering so we'll simply get the controller action from the path
        _, _, action, _ = env["PATH_INFO"].split('/', 4)
        # and automatically create a Rack::Response object and return the matching erb template as the response.body
        controller.render_response(action.to_sym)
      end
    end
  end
end

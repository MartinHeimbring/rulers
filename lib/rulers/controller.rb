require 'erubis'
require_relative 'file_model'
require 'rack/request'
require_relative 'view'

module Rulers
  # other controllers will later inherit from Rulers::Controller
  class Controller

    # we include the Rulers::Model module so we can create a new FileModel by simply calling FileModel.new (instead of Rulers::Model::FileModel.new)
    include Rulers::Model

    # the controller just saves the environment that rack feeds it
    def initialize(env)
      @env = env
    end

    # getter method for env
    def env
      @env
    end


    # use self.action to initialize rack app, and dispatch to specific action

    # this method will take the controller action (and optional routing params)
    def self.action(act, rp = {})
      # and return a proc object for the controller action
      proc { |e| self.new(e).dispatch(act, rp) }
    end


    def dispatch(action, routing_params = {})
      @routing_params = routing_params

      text = self.send(action)

      # when I want to "manually" render a view template with variables that are accessible in the view
      # I have to call ".render_responde" inside my controller
      # .render_response in return calls ".response", where we create and return a new instance of Rack::Response
      # thus if I call .get_response on my controller, I will get back a Rack::Response object
      if get_response
        # constructing a response from the values inside the @response instance variable
        # Rack::Response has an instance method called .finnish that returns a response
        # in a way that Rack expects it: [Status, Header, Response]
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
        st, hd, rs = get_response.to_a
        # and return them inside an array, just like Rack expects us to
        # we flatten rs.body, in case the rs.body is a multi-dimensional array
        [st, hd, [rs.body].flatten]
      else
        # a rack app always return a "triplet" - made up of "status code", "headers" and "body"
        # display content of text variable in response body
        # this would be a default response:

        #[200,{'Content-Type' => 'text/html'}, [text]]

        # but we are trying to implement Rails Automatic Rendering
        render_response(action.to_sym)
      end
    end


    # Change this too!
    def params
      request.params.merge @routing_params
    end


    # Rack::Response provides a convenient interface to create a Rack response.
    # It allows setting of headers and cookies, and provides useful defaults (a OK response containing HTML).
    # create a new response object
    def response(text, status = 200, headers = {})
      raise "Already respinded!" if @response
      a = [text].flatten
      @response = Rack::Response.new(a, status, headers)
    end

    # getter method for @response
    def get_response
      @response
    end

    # when render_response is called, instantiate a new Response object and pass it the erb view template as response body
    def render_response(filename, locals={})
      response(render(filename, locals))
    end

    # Rack::Request provides a convenient interface to a Rack environment. It is stateless, the environment env passed to the constructor will be directly modified.
    # create a new request oject from the environment hash that we can interact with
    def request
      # cache the result of the new rack request in @request
      @request ||= Rack::Request.new(@env)
    end

      # all instance methods of Rack::Request -->
      # []  []=  accept_encoding  accept_language  base_url  body  content_charset  content_length  content_type  cookies  delete?  delete_param  form_data?
      # fullpath GET  get?  head?  host  host_with_port  initialize  ip  link?  logger  media_type  media_type_params  options?  params  parseable_data?
      # patch?  path path_info  path_info=  port  POST  post?  put?  query_string  referer  request_method  scheme  script_name  script_name=  session
      # session_options  ssl? trace?  trusted_proxy?  unlink?  update_param  url  user_agent  values_at  xhr?

      # some instance methods of Rack::Request implemented as "getter methods" on Rulers::Controller
      def params
        request.params
      end

      def fullpath
        request.fullpath
      end

      def path
        request.path
      end


    # render erb view templates
    def render(view_name, locals = {})
      # File.join returns a new string formed by joining the strings using "/"
      filename = File.join "app", "views", controller_name, "#{view_name}.html.erb" # --> "app/views/view_name.html.erb"
      # open the file "filename" and store its content in the template variable then close the file
      template = File.read filename

      # .instance_variables gets called on the current controller instance, returning all instance variable names in an array
      # we create an empty hash (initial value for .reduce) and iterate over all instance variables of that controller instance
      # we set each KEY to the name of the respective instance variable and the VALUE to the value of that instance variable
      # then we return that hash and put it into the ivars variable
      ivars = instance_variables.inject({}) {|ha, iv| ha[iv] = instance_variable_get(iv); ha }
      # next we create a new Rulers::View object and pass the filename, the ivars and the locals to it
      # inside Rulers::View.new.result I also instantiate a new eruby object and return the resulting template
      Rulers::View.new(template, ivars, locals).result
    end

    # find out controller_name in order to dynamically compose the file_path to the file we want to render with erubis
    def controller_name
      # find name of self.class / e.g. PeopleController
      klass = self.class
      # remove -Controller from class name
      klass = klass.to_s.gsub /Controller$/,""
      # call .to_underscore on the class name
      Rulers.to_underscore klass
    end
  end
end

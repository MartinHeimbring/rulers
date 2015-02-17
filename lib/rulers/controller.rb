require 'erubis'
require_relative 'file_model'
require 'rack/request'

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
    def render_response(*args)
      response(render(*args))
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
      # create a new instance of Eruby and instantiate it with the template
      eruby = Erubis::Eruby.new(template)
      # .result() accepts values for variables that get displayed in the erb template:
      # example: Here is a <%= variable %>
      # eruby.result(:variable => "variable")
      # --> Here is a variable
      # we make any variables we pass into the "locals" Hash available in the view
      # and also merge the env into the locals Hash
      # so we can always access it in the view
      eruby.result locals.merge(:env => env)
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

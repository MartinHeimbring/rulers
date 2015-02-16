require 'erubis'

module Rulers
  # other controllers will later inherit from Rulers::Controller
  class Controller
    # the controller just saves the environment that rack feeds it
    def initialize(env)
      @env = env
    end

    # getter method for env
    def env
      @env
    end

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
      # so we can access it in the view
      eruby.result locals.merge(:env => env)
    end

    # find out controller_name
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

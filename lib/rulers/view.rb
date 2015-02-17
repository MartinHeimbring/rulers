require 'erubis'


module Rulers
  class View
    attr_reader :template, :ivars, :locals
    def initialize(template, ivars, locals)
      @template = template
      @ivars = ivars
      @locals = locals
    end

    def result
      # create a new eruby instance and instantiate it with a template
      eruby = Erubis::Eruby.new(template)
      # .result() accepts values for variables that get displayed in the erb template:
      # example: Here is a <%= variable %>
      # eruby.result(:variable => "variable")
      # output --> Here is a variable
      # we make all instance variables of the controller available in the view
      # we also any variables we pass into the "locals" Hash
      eruby.result ivars.merge(locals)
    end
  end
end
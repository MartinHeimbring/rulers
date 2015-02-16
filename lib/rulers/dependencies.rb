# monkey patch all objects to handle missing constant
# this is used to autoload controller files on the fly
class Object
  # invoked when a reference is made to an undefined constant
  # e.g. when the router fetches the name of the controller from the env PATH_INFO
  # and we try to const_get the name of the controller and instantiate that controller
  # but we haven't required that controller manually in config/application.rb
  def self.const_missing(c)
    # in the router we get the name of the controller out of env["PATH_INFO"], capitalize it and append "Controller"
    # so from a path like "/people/new" we'd construct a controller name: "PeopleController"
    # all we have to do now is turn PeopleController into the respecive file name: people_controller
    # and we do that by calling .to_underscore on it
    # and then require that file
    require Rulers.to_underscore(c)
    # and return the correct controller name
    Object.const_get(c)
    # in our sample case: PeopleController
    # so that we can instantiate a new PeopleController later on
  end
end

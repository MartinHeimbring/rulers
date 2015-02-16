# monkey patch all objects to handle missing constant
# this is used to autoload controller files on the fly
class Object
  # invoked when a reference is made to an undefined constant
  # e.g. when the router fetches the name of the controller from the env PATH_INFO
  # and we try to const_get the name of the controller and instantiate that controller
  # but we haven't required that controller manually in config/application.rb
  def self.const_missing(c)
    #  const_missing will return nil if you’re already in the middle of another const_missing.
    return nil if @calling_const_missing
    # from here on we are running .const_missing
    @calling_const_missing = true
    # in the router we get the name of the controller out of env["PATH_INFO"], capitalize it and append "Controller"
    # so from a path like "/people/new" we'd construct a controller name: "PeopleController"
    # all we have to do now is turn PeopleController into the respecive file name: people_controller
    # and we do that by calling .to_underscore on it
    # and then require that file
    require Rulers.to_underscore(c)
    # we try to find the class within the file we just required and store it in the "klass" variable
    klass = Object.const_get(c)
    # if the file doesn't exist or the class name doesn't exist
    # the current method will stop right after line 20
    # because .const_get will invoke .const_missing and would recurse forever
    # because a nonexistend class/file can't ever be found
    # but we handle this scenario on line 10:
    # where we return nil so we won't be caught in an infinite loop)

    # but if the controller class can be found and get returned by .const_get
    # we set @calling_const_missing to false (because this process is over)
    @calling_const_missing = false
    # and return the correct controller name
    # in this sample case: PeopleController
    # so that we can instantiate a new PeopleController later on
    klass
  end
end

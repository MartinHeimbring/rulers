module Rulers
  class Application
    def get_controller_and_action(env)
      # We split the url in "PATH_INFO" at '/' (PATH INFO could look like this: "/people/new")
      # But we only split it 4 times
      # the first part will be an empty string so we put it into the "_" variable --> because we don't care about it ^^
      # the next var is cont (for controller) and the one after that action.
      # the last variable is "after" and we simply put the rest of the PATH_INFO into that one
      _, cont, action, after = env["PATH_INFO"].split('/', 4)
      # Next we capitalize the controller name that we got out of the url
      cont = cont.capitalize # "People"
      # And concatenate it with "Controller" to get the respective controller name
      cont += "Controller" # "PeopleController"
      # at last we return an array containing only two elements (both strings):
      # the name of the controller and the name of the action
      [Object.const_get(cont), action]
    end
  end
end
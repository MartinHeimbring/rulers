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


    # Define route to save rules in an instance of RouteObject

    def route(&block)
      @route_obj ||= RouteObject.new
      # instance_eval evaluates a string containing Ruby code, or the given block, within the context of the receiver (obj).
      # In order to set the context, the variable self is set to obj while the code is executing,
      # giving the code access to obj's instance variables and private methods.
      # When instance_eval is given a block, obj is also passed in as the block's only argument.
      # that's the reason why we use .instance_eval for DSL's
      @route_obj.instance_eval(&block)
    end

    # use get_rack_app to route to controller actions

    def get_rack_app(env)
      # this exception takes care of the case that no routes are defined in the config.ru file
      raise "No routes!" unless @route_obj
      # if routes are defined we match the current url to the routes we have already defined
      @route_obj.check_url env["PATH_INFO"]
    end

  end
end




class RouteObject
  # we already predefine a few "default" routes in a config.ru file
  # we call app.route and pass in a block of code thus creating a new RouteObject
  def initialize
    @rules = []
  end


  # match expects a URL and two arguments: a destination and a hash of options
  def match(url, *args)
    options = {}
    options = args.pop if args[-1].is_a?(Hash)
    options[:default] ||= {}

    # set dest to nil (in case line 52 doesn't get executed)
    dest = nil
    # the destination is the argument
    dest = args.pop if args.size > 0
    # raise an error if there are still args left after popping dest out
    raise "Too many args!" if args.size > 0

    # we take the URL and split it on slashes
    parts = url.split("/")
    # select the parts of that url that are not empty strings
    parts.select! { |p| !p.empty? }

    vars = []
    # next we map each piece of the URL to regular expression
    regexp_parts = parts.map do |part|
      # if the first character of the string is ":"
      if part[0] == ":"
        # while iterating over all URL parts
        # I keep track of a list of variable names ("vars")
        # so that after I run the regular expression
        # I'll be able to match up captured values from parenthesis expressions with names
        # I'll use that within the check_url method while iterating over all matches
        vars << part[1..-1]
        "([a-zA-Z0-9]+)"
      # if the first character of the string is "*"
      elsif part[0] == "*"
        vars << part[1..-1]
        "(.*)"
      else
        part
      end
    end

    # and put together a final regular expression from all regex parts
    regexp = regexp_parts.join("/")
    # we put all routing rules into a hash
    @rules.push({
      :regexp => Regexp.new("^/#{regexp}$"),
      :vars => vars,
      :dest => dest,
      :options => options,
    })
  end



  # match rules to url and route to specific controller action.
  #
  # 1. the router just applies them in order -- if more than
  #    one rule matches, the first one wins.
  # 2. the second argument can be a Rack application,
  #    which Rails then calls.

  def check_url(url)
    # go through all "rules"
    @rules.each do |r|
      # until a rule matches the url
      m = r[:regexp].match(url)

      # proceed if a match is found
      if m
        options = r[:options]
        # if the regex matches we create a "params" object
        params = options[:default].dup ######################################################## lookup .dup !!!
        # and match up variable names with the parts that the regular expression captured
        r[:vars].each_with_index do |v, i|
          params[v] = m.captures[i] ########################################################### lookup .caputes !!!
        end
        dest = nil
        # if the rule has a destination (like "quotes#index") we call get_dest
        # to turn that into a Rack application through get_dest:
        if r[:dest]
          return get_dest(r[:dest], params)
        else
          # otherwise I get the controller + action names out of the params hash
          controller = params["controller"]
          action = params["action"]
          # and call get_dest to create a rack app out of the controller action
          return get_dest("#{controller}" + "##{action}", params)
        end
      end
    end

    nil
  end

  def get_dest(dest, routing_params = {})
    # first we check if dest responds to call and return it if it does
    # so if we pass in a rack app we can just use it!
    return dest if dest.respond_to?(:call)
    # otherwise we check if the destination is in a format like "quotes#index"
    # i.e. anything but "#" separated by "#" and then again any other string of characters
    if dest =~ /^([^#]+)#([^#]+)$/
      # I save both parts as a variable $1 and $2 --> e.g. $1 =  quotes, $2 = index
      # then I lookup the controller name
      # and capitalize it
      name = $1.capitalize
      # so I can interpolate it and use const_get to lookup the respective controller
      cont = Object.const_get("#{name}Controller")
      # then I call .action on the controller, effectively turning the controller action into a rack app
      return cont.action($2, routing_params)
    end
    # if the input for dest is rack app or doesn't match the format I expect, I raise an error:
    raise "No destination: #{dest.inspect}!"
  end
end
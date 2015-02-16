module Rulers
  def self.to_underscore(string)
    # replace double colons with a slash
    # for namespace cases like Namespace::Controller
    word = string.to_s.gsub(/::/, '/')
    # gsub any two or more consecutive capital letters
    # followed by a lowercase letter
    # replace the first thing in parantheses with itslef + "_"
    # and return the second thing in parantheses next
    # doing this "BOBSays" is turned to "BOB_says"
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    # next we substitute any lowercase()-number)-uppercase
    # to lowercase-()number-)underscore-uppercase
    # e.g. "a7D" into "a7_D"
    # or "PeopleController" to "People_Controller"
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    # finally we turn all dashes into underscores
    word.tr!("-", "_")
    # and downcase everything
    word.downcase!
    # now we can turn controller names like "UsersController"
    # into "users_controller"
    word
  end
end
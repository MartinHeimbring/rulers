require "rack/test"
require "test/unit"

# Always use local Rulers first for the test (and not the rulers gem itself)
# we prepend the absolute path to the 'rulers.rb' file to the load path so it will be loaded first
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
# so that we can require in one word
# and be sure that the rulers.rb project file will get loaded and not the gem that we installed on this machine
require "rulers"

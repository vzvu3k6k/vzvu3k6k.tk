require "rack/jekyll"
require 'pry'

run Rack::Jekyll.new(baseurl: "")

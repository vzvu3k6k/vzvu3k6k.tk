require "rack/jekyll"
require 'pry'

app = Rack::Jekyll.new.instance_eval do
  @mimes << %r[^/CNAME$]
  self
end

run app

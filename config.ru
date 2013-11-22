require "rack/jekyll"
require 'pry'

app = Rack::Jekyll.new(baseurl: "").instance_eval do
  @mimes << %r[^/CNAME$]
  self
end

run app

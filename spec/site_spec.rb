require "sitespec"
require "rack/jekyll"
require "nokogiri"

module Rack
  class Interceptor # todo: a better name
    def initialize(app)
      @app = app
      @cache = {}
    end

    def call(env)
      path = env["PATH_INFO"]
      warn "Rack::Interceptor is intercepting #{path}."
      @cache[path] ||= @app.call(env).tap do |triplet|
        warn "Rack::Interceptor is making a cache of '#{path}'."

        # todo:
        #   * Add server error handling as Sitespec::Builder#call does
        #   * Give correct args to Sitespec::Request.new
        request = Sitespec::Request.new(:get, path)
        response = Sitespec::Response.new(*triplet)
        Sitespec::Writer.write(request, response)
      end
    end
  end
end

Sitespec.configuration.application = Rack::Interceptor.new(Rack::Jekyll.new(baseurl: ""))

Thread.new {
  Rack::Server.start(app: Sitespec.configuration.application, Port: 9292)
}

def wget(path)
  command = "wget 'http://0.0.0.0:9292#{path}' -O /dev/null --quiet -p -r -l 0"
  system(command)
end

describe "This site" do
  include Sitespec
  it "provides the sitemap" do
    # require 'pry';binding.pry
    # exit
    get "/sitemap.xml"

    sitemap = Nokogiri::XML.parse(@response.body)
    locations = (sitemap / "loc").map(&:text)
    # it provides every page in its sitemap
    locations.each do |location|
      path = URI.parse(location).path
      path = "/index.html" if path == "/" # adhoc
      wget path
      # system("wget -p '#{location}'")
    end
  end
end

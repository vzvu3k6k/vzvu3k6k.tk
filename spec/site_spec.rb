require "sitespec"
require "rack/jekyll"
require "nokogiri"

module Sitespec

  module_function

  def get_with_resources(path, params = {}, env = {})
    get(path, params, env)

    if @response.status == 200 && @response.header["Content-Type"] == "text/html"
      extract_urls(@response.body, path).each do |url|
        get_with_resources url unless @processed_paths[url]
      end
    end
  end

  def extract_urls(html, current_path)
    html = Nokogiri::HTML.parse(html)
    tag_attr = [["a", "href"], ["img", "src"], ["script", "src"], ["link", "href"]]
    urls = tag_attr.flat_map do |(tag, attr)|
      html.search(tag).map {|node| node[attr]}.compact
    end

    # FIXME: This removes all URLs with a host or a schema whether or not it points your rack app.
    site_urls = urls.reject {|url| url.match(%r[^(\w+:|//)]) }
                    .map {|url| URI.join("http://example.org", current_path, url).path }
  end

  def process_once(*args)
    path = args[1]
    @processed_paths ||= {}
    @processed_paths[path] ||= _process(*args)
  end

  alias _process process
  alias process process_once
end

Sitespec.configuration.application = Rack::Jekyll.new.instance_eval do
  @mimes << %r[^/CNAME$]
  self
end

describe "This site" do
  include Sitespec

  it "provides the following files" do
    get "/index.html"
    get "/CNAME"
    get "/robots.txt"
  end

  it "provides the sitemap" do
    get "/sitemap.xml"

    sitemap = Nokogiri::XML.parse(@response.body)
    locations = (sitemap / "loc").map(&:text)

    # it provides every page in its sitemap and resource used or referenced in pages
    locations.each do |location|
      path = URI.parse(location).path
      get_with_resources path
    end
  end
end

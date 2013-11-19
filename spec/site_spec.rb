require "sitespec"
require "rack/jekyll"
require "nokogiri"

class Spider
  def initialize(app)
    @app = app
    @cache = {}
  end

  def call(env)
    path = env["PATH_INFO"]

    unless @cache[path]
      @cache[path] = @app.call(env)
      status, header, body = *@cache[path]

      if status == 200 && header["Content-Type"] == "text/html"
        extract_urls(body, path).each do |url|
          Sitespec.get url unless @cache[url]
        end
      end
    end

    @cache[path]
  end

  def extract_urls(html, current_path)
    html = Nokogiri::HTML.parse(html.first)
    tag_attr = [["a", "href"], ["img", "src"], ["script", "src"], ["link", "href"]]

    urls = tag_attr.flat_map do |(tag, attr)|
      html.search(tag).map {|node| node[attr]}.compact
    end

    # FIXME: This removes all URLs with a host or a schema whether or not it points your rack app.
    site_urls = urls.reject {|url| url.match(%r[^(\w+:|//)])}
                    .map {|url| URI.join("http://example.org", current_path, url).path}
  end
end

Sitespec.configuration.application = Spider.new(Rack::Jekyll.new(baseurl: ""))

describe "This site" do
  include Sitespec
  it "provides the sitemap" do
    get "/sitemap.xml"

    sitemap = Nokogiri::XML.parse(@response.body)
    locations = (sitemap / "loc").map(&:text)

    # it provides every page in its sitemap and resource used or referenced in pages
    locations.each do |location|
      path = URI.parse(location).path
      get path
    end
  end
end

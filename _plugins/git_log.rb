# License: [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

require 'grit'
require 'time'
require 'webrick/htmlutils'

module Jekyll
  class GitLog < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
    end

    def render(context)
      env = context.environments[0]

      path = env["page"]["path"]
      log = `git log --format=raw --follow -- #{Shellwords.escape(path)}`
      repo = Grit::Repo.new(".")
      commits = Grit::Commit.list_from_string(repo, log)

      result = %q{<ul>}
      commits.each do |i|
        id, datetime, message = [i.id, i.authored_date.iso8601, i.short_message].map(&WEBrick::HTMLUtils.method(:escape))
        result << %Q{<li><a href="#{env["site"]["commit_permalink"].sub("{id}", id)}"><time>#{datetime}</time> <span>#{message}</span></a></li>}
      end
      result << %q{</ul>}
    end
  end
end

Liquid::Template.register_tag("git_log", Jekyll::GitLog)

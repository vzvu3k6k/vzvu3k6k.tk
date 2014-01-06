require 'git'
require 'webrick/htmlutils'

module Jekyll
  class GitLog < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
    end

    def render(context)
      path = context.environments[0]["page"]["path"]
      commit_hashes = `git log --format="%H" --follow -- #{Shellwords.escape(path)}`.split
      repo = Git.open(".")
      commit_objects = commit_hashes.map(&repo.method(:object))

      result = %q{<ul class="history">}
      commit_objects.each do |i|
        sha, datetime, message = [i.sha, i.date.iso8601, i.message.split("\n").first].map(&WEBrick::HTMLUtils.method(:escape))
        result << %Q{<li><a href="https://github.com/vzvu3k6k/vzvu3k6k.github.com/commit/#{sha}"><time>#{datetime}</time> <span>#{message}</span></a></li>}
      end
      result << %q{</ul>}
    end
  end
end

Liquid::Template.register_tag("git_log", Jekyll::GitLog)

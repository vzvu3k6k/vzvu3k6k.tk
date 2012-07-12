---
layout: post
title: 日付の表示形式を変更する
---

日付を"yyyy年mm月dd日"や"yyyy-mm-dd"などと表示したい。JekyllはLiquidというテンプレートエンジンを使っているので、Liquidのフィルターというのを定義してやればいいらしい。[jekyll/lib/jekyll/filters.rb at master · mojombo/jekyll · GitHub](https://github.com/mojombo/jekyll/blob/master/lib/jekyll/filters.rb "jekyll/lib/jekyll/filters.rb at master · mojombo/jekyll · GitHub")を参考にした。

`_plugins`に`filters.rb`とか適当なファイルを作って、

<pre><code>
module Jekyll
  module Filters
    def date_to_ja_string(date)
      date.strftime("%Y年%m月%d日")
    end
    
    def date_to_valid_date_string(date)
      date.strftime("%Y-%m-%d")
    end
  end
end
</code></pre>

と書いた。`Jekyll::Filters`に追加するのは行儀が悪いだろうか。

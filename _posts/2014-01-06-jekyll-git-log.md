---
layout: post
title: Jekyllに更新履歴を表示する
---

* [俺の最強ブログ システムが火を噴くぜ - てっく煮ブログ](http://tech.nitoyon.com/ja/blog/2012/09/20/moved-completed/)
* [Pull RequestとCIを使ったGitHub Flowなブログ環境を作ってみた - アインシュタインの電話番号](http://blog.ruedap.com/2013/11/11/github-flow-blog)

ブログの記事を黙って修正するのは不誠実なので、修正箇所や修正日時を明示するべきだという考え方もあるが、修正が度重なると打ち消し線や「○年○月○日追記:」などが錯綜して読みづらい。記事をGitで管理していてGitHubに載せているなら、そこの履歴を参照してもらえばいいではないか、みたいな話。

上記2つはGitHubのHistoryへのリンクを貼るというアプローチだが、ここでは[ssig33.com - コンテンツに履歴表示するもの作った](http://ssig33.com/text/%E3%82%B3%E3%83%B3%E3%83%86%E3%83%B3%E3%83%84%E3%81%AB%E5%B1%A5%E6%AD%B4%E8%A1%A8%E7%A4%BA%E3%81%99%E3%82%8B%E4%BD%9C%E3%81%A3%E3%81%9F)のような形式でページ内に更新履歴を表示してみる。

JavaScriptから[GitHubのAPI](http://developer.github.com/v3/repos/commits/)を叩けばファイルの更新履歴は取れるんだけど、[認証していないと1時間あたり60回までしかコールできない](http://developer.github.com/v3/#rate-limiting)し、要素が動的に追加されるとなんとなく落ち着かない感じがする。Jekyllでページを生成するときに更新履歴を書きだすことにした。[grit](https://rubygems.org/gems/grit)で``Grit::Commit.list_from_string(Grit::Repo.new("."), `git log --pretty=raw`)``などとすれば`Grit::Commit`の配列が返ってくる。

「マークアップを変えた」みたいな本質的ではない変更まで履歴に表示されるのが気にならなくもない。更新履歴に出したくないコミットのメッセージには`[minorfix]`という文字列を入れる、みたいなルールを決めるといいかもしれない。

ところで、Gitのコミットログは改変できるし、GitHub上のリポジトリも`git push -f`で上書きできるので、GitHubのHistoryは何の保証にもならない。「こっそり記事を書き換えただろ」と言われると反証するのが難しい気がする。この点については更新履歴を保存してない大多数の他のブログサービスと変わりがない。

## 使い方

1. [_plugins/git_log.rb](https://github.com/vzvu3k6k/vzvu3k6k.github.com/tree/source/_plugins/git_log.rb)をコピーして、ソース内のURLを修正する。
2. [_layout/post.html](https://github.com/vzvu3k6k/vzvu3k6k.github.com/tree/source/_layouts/post.html)のように、更新履歴を表示したいページに<code>{&#37; git_log &#37;}</code>を挿入する。

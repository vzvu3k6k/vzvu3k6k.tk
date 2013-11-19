---
layout: post
title: grep-ruby-token
---

[vzvu3k6k/grep-ruby-token](https://github.com/vzvu3k6k/grep-ruby-token/)

[uu59のメモ | git-grep-token-ruby作った（けど低品質）](http://blog.uu59.org/2013-09-16-grep-token-ruby.html)が便利そうだったので[parser](http://rubygems.org/gems/parser)でやってみた。

GitHubに上げたけど誰も見てないだろうと思って`git push -f`をバシバシ使ってたら、[なかったことにしたコミットのほうにリンクされて](https://twitter.com/uu59/statuses/380315860381859840)冷や汗が出た。

オリジナルのgit-grep-token-rubyではripperを使ってコードをパースしているのだが、ripperから出力される構文木はやや複雑で扱いづらいところがある。Rubyのコードをパースするライブラリはripperの他にもいくつかあり、parserというシンプルすぎる名前のライブラリが一番後発で使いやすそうだったのでこれを使うことにした。調べた内容については[Rubyのコードをパースするライブラリ](http://qiita.com/vzvu3k6k/items/dd45ad293ae2d60c7a4e)というタイトルでまとめた。内容が浅すぎてあまりまとまってない。

parserは扱いやすいASTを出力してくれるが、複雑なコードではパースが失敗することがある。ripperを使ってparser式の簡潔なASTを生成したほうが楽なのではないかとも思うが、それはparserの作者も考えたはずで、<q cite="http://whitequark.org/blog/2012/10/02/parsing-ruby/">Unless you’re implementing something that obeys the garbage-in garbage-out rule, Ripper isn’t very useful. To make it worse, there isn’t a cross-platform gemification of Ripper, or at least I was unable to find one.</q>というあたり、特に後者が許容できなかったのだろうか。

## 関連
* [短いメソッドは grep で探すの大変ですよね - Watson's Blog](http://watson1978.github.io/blog/2012/12/09/find-methods/) - ripperを利用したトークン単位のRubyのソースコード検索

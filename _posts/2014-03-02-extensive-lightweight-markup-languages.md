---
layout: post
title: 軽量マークアップ言語の拡張
---

世間には[AsciiDoc](http://www.methods.co.nz/asciidoc/), [reStructuredText](http://docutils.sourceforge.net/rst.html), [markdown](http://daringfireball.net/projects/markdown/)といった多種多様な軽量マークアップ言語が存在する。頭ひとつ抜けた感のあるmarkdownの中でも、[Markdown Extra](http://michelf.ca/projects/php-markdown/extra/), [MultiMarkdown](http://fletcherpenney.net/multimarkdown/), [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown)などの亜種変種がひしめきあっている。

あらゆるニーズを満たす軽量マークアップ言語は作りようがないし、それぞれのアプリケーション固有の機能が必要になることもある。たとえばmention機能（`@username`と書いたらユーザーページにリンクされるようにして、言及されたユーザーには通知を出す）とか。

既存のマークアップ言語に拡張機能を追加するのはそれほど容易ではない。正規表現などで適当に置換してしまうと、他の機能と衝突して予期しない結果を生むことがある。たとえば前述のmention機能を実装するとき、`source.gsub(/@(\w+)/, '<a href="/users/\1">@\1</a>')`などとしてしまうと、`[email](mailto:admin@example.com)`や``ここで`@source`というインスタンス変数が…``といったテキストにも反応してしまい、ユーザーの期待とは異なる出力になる。

衝突を避けるためには、コードブロックやリンクなどの内部では置換しないといった対応が必要になる。しかし、パーサー本体に手を加えるとなると、自分の加えた変更が上流にマージされない場合にはフォーク版をメンテナンスすることになり、コストがかさむ。とはいえ、markdownの構文を独自にパースするのも同様に手間が掛かる。

以下で軽量マークアップ言語をさまざまなレイヤーで拡張する方法をいくつか紹介する。

## パーサーのフック機能など

特定の要素をパースしたときの処理をフックして変更する機能を備えたり、ユーザーが構文木を操作できるようにしているパーサーもある。

たとえばRuby用のmarkdownライブラリ[redcarpet](https://github.com/vmg/redcarpet)はフック機能を持っている。

## pandoc --filter

Haskell製のマークアップ言語変換ツールであるpandocには、JSONで出力した抽象構文木を外部のプログラムを使って変換する機能がある。外部のプログラムは任意の言語で記述できる。

* [Pandoc - Scripting with pandoc](http://johnmacfarlane.net/pandoc/scripting.html)
* [pandocでMarkdownを拡張しコードをインポート出来るfilterを書く | Web scratch](http://efcl.info/2014/0301/res3692/) - CodeBlocks内に`$import(src/example.js)`と書くと`src/example.js`の内容が展開されるフィルターをJavaScript(node.js)で記述した例。

## html-pipeline

[html-pipeline](https://github.com/jch/html-pipeline)はHTML（NokogiriのDocument）を変換する単機能のフィルターを繋げて文書を加工していくrubygem。`pandoc --filter`のASTがJSONではなくHTMLになったものと思えばよい。

前述のmention機能は[html-pipeline/lib/html/pipeline/@mention_filter.rb](https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/%40mention_filter.rb)として同梱されている。

## reStrucuredTextの拡張可能な構文

reStrucuredText(reST)はPythonコミュニティに出自を持つマークアップ言語。Javaに対するJavaDoc、Rubyに対するRDocのPython版のような位置付け。markdownより多機能なので[仕様](http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html)は割と大きめ。

directiveとroleという拡張性のある構文が用意されている。

* divectives
  * [Directives](http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#directives)
  * [reStructuredText Directives](http://docutils.sourceforge.net/docs/ref/rst/directives.html)
  * [Creating reStructuredText Directives](http://docutils.sourceforge.net/docs/howto/rst-directives.html)
* roles
  * [Interpreted Text](http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#interpreted-text)
  * [reStructuredText Interpreted Text Roles](http://docutils.sourceforge.net/docs/ref/rst/roles.html)
  * [Creating reStructuredText Interpreted Text Roles](http://docutils.sourceforge.net/docs/howto/rst-roles.html)

前述のmention機能をreSTの枠組みの中で表現するとしたら、roleを使って`` :at:`username` ``という感じで書くのではないかと思う。ちょっとまどろっこしい。

## 所感

拡張されたmarkdownの仕様とreSTの仕様は結構重複している。「reSTとか仕様大きすぎるよね、markdownぐらいシンプルなのがいいよね」という感じで普及したあと、「大規模な文書もmarkdownで書きたい、機能が足りないからどんどん拡張しよう！」と頑張ったらreSTみたいなものがいくつも出来てしまったという感じなのかもしれない。

直接markdownに[数式記法を追加](http://qiita.com/Qiita/items/c686397e4a0f4f11683d#2-9)したりするより、プレーンなmarkdownにreSTの構文を部分的に導入したほうがいいんじゃないかという気もする。[reSTはdirectiveとroleで数式を記述できる](http://docutils.sourceforge.net/FAQ.html#how-can-i-include-mathematical-equations-in-documents)。

既存のマークアップ言語にちょっと記法を追加したいときには、HTMLの出力が得られればOKというケースが多いと思うので、html-pipelineのようにHTMLに落としてからDOMをいじるのが手軽で現実的だと思う。ただし既存の構文を拡張するとなるとHTMLに変換してからではうまくいかないこともあるはずで、そういう場合にはパーサーをフックしたり、拡張した構文を自分で部分的にパースしたりということになる。

## 元ネタとか

* [pandocでMarkdownを拡張しコードをインポート出来るfilterを書く | Web scratch](http://efcl.info/2014/0301/res3692/)
* [「Markdown Parser拡張するよりPipeline風に処理していく方が筋良さそう」](https://twitter.com/r7kamura/status/432422287845777408)
* [Markdownなど - Weblog - Hail2u.net](http://hail2u.net/blog/software/markdown-etc.html)

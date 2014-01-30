---
layout: post
title: https://github.com/robots.txt
---

冒頭に

    # If you would like to crawl GitHub contact us at support@github.com.
    # We also provide an extensive API: http://developer.github.com/

と人間向けのメッセージがある。

ボットは基本的に[/humans.txt](https://github.com/humans.txt)にしかアクセスできないことになっている。主だったサーチエンジンのクローラは別扱いになっているが、サーバーの負担を避けるためなのか、かなり詳細にDisallowが設定されている。User-Agentごとに同じAllowとDisallowの設定が繰り返されていてムズムズする。robots.txtがあまり複雑なフォーマットをサポートするとパーサーを書くのが大変だろうから、仕方がないのだろうか。

目を引いたのは

    Disallow: /ekansa/Open-Context-Data
    Disallow: /ekansa/opencontext-*

という部分。個人のリポジトリがDisallowに指定されている。[ekansa/Open-Context-Data · GitHub](https://github.com/ekansa/Open-Context-Data)のREADMEによると、このリポジトリには総計3GB以上のXMLファイルが含まれていて、GitHubに変更をpushしようとするとHTTP 500 range errorが返ってきてしまうなどと書かれている。あまりにサイズが大きすぎるのでクロールが禁止されてしまったらしい。

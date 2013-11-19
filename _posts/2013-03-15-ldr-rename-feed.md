---
layout: post
title: Livedoor Readerにフィードをリネームする機能を追加するユーザースクリプト
---

[LDR-Rename-Feed](https://github.com/vzvu3k6k/LDR-Rename-Feed)

`:rename`で今開いているフィードをリネームできる。

---

[Google Readerが廃止されるという告知](http://googleblog.blogspot.jp/2013/03/a-second-spring-of-cleaning.html)があってから、[Livedoor Reader](http://reader.livedoor.com/)が移行先として注目を集めている。現在"Livedoor Reader"でググると、検索結果の上位にGoogle Readerからの移行の手順を解説した記事がずらりと並ぶ。

Google ReaderにあってLivedoor Readerにない機能の一つに、フィードのリネームがある。どうでもよさそうな機能だけど、[Yahoo! Pipes](http://pipes.yahoo.com/)のユーザーにとっては結構重要。これはネット上から情報を取得、加工してJSONやRSSなどで出力する「パイプ」を作れるサービスで、たとえばフィードを公開していない日記サイトをスクレイピングしてRSSを作ったりできる。パイプには利用者がパラメーターを設定できるものがあり、これによって、[特定のユーザーの最近のgistの一覧をRSSとして出力する](http://pipes.yahoo.com/pipes/pipe.info?_id=fb4ff2206c3e3aec2c49072ce7c60d53)とか、[指定したはてなグルーブの日記のフィードをまとめる](http://pipes.yahoo.com/pipes/pipe.info?_id=TssmX7bb2xGYLar_l7okhQ)といったことができるのだが、パイプから出力されるフィードのタイトルを変更する機能はない。前者のパイプではAさんのgist一覧とBさんのgist一覧のタイトルが同じ"gist-updates"になってしまう。

「どうせ読むんだからタイトルなんかどうでもいい」と割り切るのもありかと思うが、せっかくなのでリネームっぽい動作をするユーザースクリプトを書いた。[Karafuto Blog - livedoor Readerのフィードの名前を変更する User JavaScript](http://karafuto50.blog117.fc2.com/?no=130)を参考にした。

追記：最近のgistのフィードは`https://gist.github.com/<username>.atom`で見れる。

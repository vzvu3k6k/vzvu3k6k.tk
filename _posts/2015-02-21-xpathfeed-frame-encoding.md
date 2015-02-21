---
layout: post
title: XPathFeedの/frameで<input value="&#x2713;">などを含むページが正常に表示できない問題を直した
---

正確に書くと、HTMLのタグの属性の値に符号位置がffより大きい文字参照が含まれているページのURLをXPathFeedの`/frame?url=...`に指定すると正常に表示できないという問題。

どのサーバーを使うかによって症状は異なる。plackup(Plack 1.0034 `carton exec -- plackup app.psgi`)の場合、`Wide character outside byte range in response. Encoding data as UTF-8 at ./xpathfeed/local/lib/perl5/Plack/Util.pm line 96.`というエラーが出力され、ページが文字化けする。starman(Starman 0.4011 `carton exec -- starman --preload-app --port 5000`)では、`Wide character in syswrite at /home/vzvu3k6k/.anyenv/envs/plenv/versions/5.20.1/lib/perl5/site_perl/5.20.1/Starman/Server.pm line 561.`というエラーが出力され、空のページが表示される。

## 原因

かいつまんで書くと、暗黙的にデコードされた文字参照のせいで文字コードのupgradeが起きて文字列が破壊され、意図せずテキスト文字列が出力されてしまうのが原因らしい。それなりに調べたのでたぶん正しいと思うけど、Perl5の文字コードまわりは複雑なので、本当に間違っていないか不安。ともかく以下に詳細を書く。

XPathFeedの/frameにスクレイピングの対象となるURLを渡すと、マウスカーソルの下にある要素を選択するXPathをサジェストする機能を埋め込んでiframe内に表示してくれる。このページを正しく表示するために、HTML::ResolveLinkというモジュールで対象ページの相対パスを絶対パスに置換している。

HTML::ResolveLinkはHTMLをパースするのにHTML::Parserというモジュールを使っている。これはHTMLのノードを深さ優先で辿りながら、ノードの内容を引数にしてハンドラを呼び出すというもので、HTML::ResolveLinkはハンドラの中で属性を適切に書き換えながらHTMLを文字列として書き出す。（参照: [lib/HTML/ResolveLink.pm - metacpan.org](https://metacpan.org/source/MIYAGAWA/HTML-ResolveLink-0.05/lib/HTML/ResolveLink.pm)）

HTML::Parserはデフォルトでは属性の値に含まれる文字参照をデコードする。例えば、`<input value="&#x2713;">`のvalue属性の値は、`"\x{2713}"`に相当する文字列に変換される（HTML::Parserのソースは確認していないが、Devel::Peekで両者を見たところ同じ値っぽかった）。これはテキスト文字列である。符号位置がffより大きいとUTF8フラグが立つ。

一方、XPathFeedからHTML::ResolveLinkに渡されるHTMLのソースは常にエンコードされている（[xpathfeed/XPathFeed.pm#L145](https://github.com/onishi/xpathfeed/blob/7500540a41a4c2b753acd64dc105bc08812a798d/lib/XPathFeed.pm#L145)）。つまりバイナリ文字列だ。UTF8フラグは常に落ちている。HTML::Parserは、前述の文字参照のデコードを除けば、コールバックにバイナリ文字列をそのまま渡す（`$parser->utf8_mode(1)`が設定されているときは例外）。

結果として、HTML::ResolveLinkの中でHTMLを書き出すとき、UTF8フラグが立った文字列と立っていない文字列が連結されることがある。このようなとき、Perlはフラグが立っていない文字列の文字コードをlatin-1と仮定してデコードする（これをupgradeという）ので、HTMLのソースがlatin-1以外だと文字化けしたテキスト文字列ができてしまう。連結結果の文字列のUTF8フラグは常にオンになる。

XPathFeedとapp.psgiは`XPathFeed#_resolve()`から返されるHTML文字列がUTF-8のバイナリ文字列であることを期待して、そのまま外部に送信しようとする。plackupはデータにwide characterがあったらエラーメッセージを表示して、強制的にUTF-8としてエンコードしてからsyswriteに渡すので、文字化けしたページが表示される。starmanはデータをそのままsyswriteに渡す。データにUTF8フラグが立っていて、latin-1で表現できない文字が含まれていると、syswriteは例外を吐いて処理を終了するので、ページの内容が空になる。

### 参考

- [perlunitut - Perl における Unicode のチュートリアル - perldoc.jp](http://perldoc.jp/docs/perl/5.20.1/perlunitut.pod): 「テキスト文字列」と「バイナリ文字列」の定義など。
- [perlunifaq - Perl Unicode FAQ - perldoc.jp](http://perldoc.jp/docs/perl/5.20.1/perlunifaq.pod)
  - [デコードしないとどうなるの?](http://perldoc.jp/docs/perl/5.20.1/perlunifaq.pod#What32if32I32dont32decode63)では、テキスト文字列とバイナリ文字列を一緒に使うと常にupgradingするようにも取れるが、upgradingするかどうかはUTF8フラグの有無で決まる。UTF8フラグが立っている文字列は必ずテキスト文字列だが、UTF8フラグが立っていないテキスト文字列もありえる。
- [第16回　Perl内部構造の深遠に迫る（2）：Perl Hackers Hub｜gihyo.jp … 技術評論社](https://gihyo.jp/dev/serial/01/perl-hackers-hub/001602)
- [UTF8 フラグあれこれ - daily dayflower](http://d.hatena.ne.jp/dayflower/20080219/1203493616)

## 対策

`Encode::encode()`してからHTML::ResolveLinkに渡すのをやめて、HTML::ResolveLinkの返り値を`Encode::encode()`するように修正した。エスケープは出力の直前に行うべきという考え方を引けば、`app.psgi`で出力する直前に`Encode::encode()`したほうがいいような気もするが、Perlの流儀を知らないので元コードに従った。

`HTML::Parser#attr_encoded(0)`で文字参照のデコードを無効にするのも試したが、HTML::ResolveLinkのエスケープで`&hearts;`のような文字参照が`&amp;hearts;`に置換されるのでうまくいかなかった。

### ついでに

`Encode::encode()`の第一引数をUTF-8に固定していると、metaタグでUTF-8以外の文字コードが指定されているとき文字化けしてしまう。代わりに`$xpf->http_result->{content_charset}`を渡すことにした。

`<input value="&#x2713;">`をHTML::ResolveLinkで処理すると`<input value="✓">`になって、これをさらにEUC-JPなどに変換すると`<input value="?">`になってしまうという問題があるのだが、/frameで属性の値が化けても大きな問題はなさそうなので対策はしていない。フィードを生成するときにはHTML::ResolveLinkを通さないので影響はない。

## プルリクエスト送った

[Fix character corruption in /frame by vzvu3k6k · Pull Request #3 · onishi/xpathfeed · GitHub](https://github.com/onishi/xpathfeed/pull/3)

テストも書くべきなのか迷ったけど、HTTP::Messageのテストみたいになってしまう気がするのでとりあえず問題の修正だけした。

### ところで

HTML::Parserはなぜ属性値以外の文字参照はデコードしないんだろう。

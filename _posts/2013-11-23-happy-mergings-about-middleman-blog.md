---
layout: post
title: happy mergings about middleman-blog
---

middleman-blogに関連するいくつかのプルリクを送ったという話。ちょっとした問題を解決しようとしたら予想外にいろいろと引っかかったので覚え書きをしておく。実用的な情報はあまりない。

## フィードが見つからない

[r7kamura blog](http://r7kamura.github.io/)をフィードリーダーに登録しようとしたが、フィードが見つからなかった。

このサイトは[Middlemanを使って生成していて、GitHub Pagesを使って公開している](http://r7kamura.github.io/2013/11/10/hello-world.html)。Middlemanを利用したブログサイトで、フィードは用意してしてもリンクを貼り忘れるというケースは時々あるようで、以前にも[オートディスカバリーを追加するプルリク](https://github.com/f440/f440.github.com/pull/1)を送ったことがあった。GitHubのリポジトリをざっと眺めてみると、`/feed.xml`があるのが確認できた。よかったよかった。

## フィードが壊れている

ところが、`http://r7kamura.github.io/feed.xml`にアクセスしてみると、フィードのタイトルが"Blog Name"になっていて、何かおかしい。よく見ると記事のURLのホスト名も`http://blog.url.com/`になっている。フィードの設定がデフォルトのままになっているらしい。これでは読者である自分が困る、ということで[feed.xmlを修正するコミット](https://github.com/r7kamura/r7kamura.github.io/commit/de4387d8e20b55dd1e95063f01b3baae953e3583)をしてプルリクを出すことにした。

上記のコミットを見てもらえば分かるように、`feed.xml`の実体はただのテンプレートだから簡単に書き換えることができる。ただ、`site_url`という変数にホスト名を入れるという仕組みが気になった。これではブログのホストが変わるたびにフィードのテンプレートを書き換えないといけない。ホスト名抜きのURL（`http://example.com/foo`ではなく`/foo`と指定するようなURL）ではいけないのだろうかと思って調べてみたが、Atomの`entry`要素の`id`プロパティは省略不可で、内容は完全なURLでなければいけないと定められているのでどうしようもない（参照：[RFC 4287 - The Atom Syndication Format](http://tools.ietf.org/html/rfc4287), [Make feed.xml entry URLs absolute by rmm5t · Pull Request #130 · middleman/middleman-blog](https://github.com/middleman/middleman-blog/pull/130)）。とりあえず、サイト名や著者名などが`config.rb`で定義されていたので、ドメイン名もそちらに書くように変更しておいた。

## オートディスカバリーを追加する

ついでにオートディスカバリーも追加するプルリクを書こうとしたのだが、<q cite="http://r7kamura.github.io/2013/11/10/hello-world.html">Middlemanにはブログを作るための拡張機能があるので、これを使えば簡単に雛形を生成できる</q>という一文が気になった。middleman-blogの雛形を確認してみると、`feed.xml`はあったが、オートディスカバリーはなかった。

そのまま`/feed.xml`とURLを指定するよりスマートなやり方があるのではないかと思って、Sitemapとか`asset_path`メソッドの実装とかをいろいろ調べた結果、結局URLを直接書くのがよさそうだということになった。pryでメソッドを呼び出したり変数を確認したりしつつ`show-method`でメソッドのコードを確認していくのが楽でよかった。

## Middlemanが壊れた？

Middlemanをサーバーモードで動かしているとき、`http://0.0.0.0:4567/__middleman/`にアクセスするとSitemapや設定がきれいに表示されて便利なのだが、気がついたらSitemapや設定一覧にアクセスできなくなってしまった。スタイルシートもなぜか当たっていない。設定を変更しても、これまでのコミットをリバートしても、新しいテンプレートを作っても動かない。関連しそうなGemを入れなおしてみるが改善されない。

一時間以上悩んだ気がするけど、原因は単純で、`http://0.0.0.0:4567/__middleman`ではなく`http://0.0.0.0:4567/__middleman/`を開かないといけないのだった。末尾の`/`が抜けていてもそのままページは表示されるのだが、ページ内のリソースやリンクはすべて相対URLで指定されていたので、たとえば本来なら`/__middleman/config`を読み込むべきところで`/config`を読み込んでしまう。

## テストに失敗

気を取り直してmiddleman-blogのほうに[Add autodiscovery of feed.xml to layout.erb](https://github.com/middleman/middleman-blog/commit/f81fc5f2b27826ed91d2885d5a1abde833798984)という変更を入れてから、念のため`bundle exec rake test`でテストを実行してみるとなぜか失敗した。調べてみると、もともとmiddlemanのほうに一時的にバグがあったらしい。以下のプルリクとコミットを参照。

* [add the missing file back for the automatic_alt_tag feature by stevenosloan · Pull Request #1072 · middleman/middleman · GitHub](https://github.com/middleman/middleman/pull/1072)
* [whoops, bad rename · 95c0fe6 · middleman/middleman](https://github.com/middleman/middleman/commit/95c0fe60accc2bc5a8e4d559e0263da977ddbcb2)

必要なファイルをうっかり消していたので`require`でエラーが出たという単純なバグ。上記のコミットによって修正されている。

## `bundle install`に失敗

middlemanのバグを手元で修正してテストを走らせるべく`bundle install`を実行してみるとdebuggerというgemのインストールに失敗した。ruby2.1.0-preview1で実行していたのだが、「2.1は対応していないバージョンです」という感じのメッセージが出てインストールが強制的に終了してしまう。そもそもプルリクを出すときにpreview版を使っていたのがよくなかった。

rbenvで2.0系のリリース版を入れる。gemをインストールしなおすのが面倒なのでとりあえず2.1.0-preview1の`gems`にシンボリックリンクを貼って動かしてみたが、確か[ffi](http://rubygems.org/gems/ffi)が「なんとかかんとか.soファイルが見つからないです」という感じのエラーを出したのでくじけて寝た。

## プルリクを送る

当初の目的からずいぶん離れてしまったので、とにかくfeed.xmlを修正するプルリクを送った。descriptionを書き足すために編集画面を開こうとしたら、GitHubがおかしい。プルリクエストの一覧のところが、急におかしくなった……このリポジトリ、送ったはずのプルリクが……ぜんぜんない。

![はっ！]({{ site.baseurl }}img/already-merged.png)

なるほどうわはははははは「[マージ](https://github.com/r7kamura/r7kamura.github.io/pull/1)」されていましたァァぁぁいつの間にかァァ

[github-stream](https://github.com/r7kamura/github-stream)とかでGitHubの通知をリアルタイムで確認して、即座に対応してもらったらしい。その後もいくつかプルリクを送ったら即座にマージされるという感じでテンションが上がったので、[middleman/middleman-blog](https://github.com/middleman/middleman-blog/)にもエイヤッと[Add autodiscovery of feed.xml to layout.erb](https://github.com/middleman/middleman-blog/pull/173)を送ったら、こちらもさくっとマージしてもらえた。

## その後

フィードリーダーを開いたら[人間の善性とインターネットに対する可能性を感じる記事](http://r7kamura.github.io/2013/11/15/happy-pull-request.html)が出てきた。

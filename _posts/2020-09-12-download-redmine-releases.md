---
layout: post
title: vzvu3k6k/download-redmine-releases
---

https://github.com/vzvu3k6k/download-redmine-releases

<https://redmine.org/releases/>からtarballをダウンロードする簡単なbashスクリプトを書いた。tar.gzファイルだけでも全部ダウンロードすると400MBほどある。

ソースコードを取得するだけなら<https://github.com/redmine/redmine>を使ったほうが楽だし早そうだが、今回は公式にリリースされているものを確認したかったので<https://redmine.org/releases/>を利用した。

## wgetの`--timestamping`と`--no-clobber`

スクリプトを一度実行してすべてのファイルをダウンロードしたら、次の実行では新たに追加されたファイルだけを取得したい。wgetでは次のようなオプションが使える。

* `--timestamping`: ファイルの最終更新日時から`If-Modified-Since`ヘッダーを生成して問い合わせる
* `--no-clobber`: 同名のファイルがローカルに存在していたらリクエストを送らない

バージョン番号の打たれたリリース物があとから書き換えられることはなさそうなので、今回は`--no-clobber`を使うことにした。

一部では[`--no-clobber`は同名のファイルが存在していても保存をスキップするだけでリクエストは送るよ、いや送らないぞといった混乱がある](https://stackoverflow.com/questions/4944295/skip-download-if-files-exist-in-wget#comment54212653_4944353)が、手元のwget 1.20.3では`wget --no-clobber localhost:4567/01.txt`のようなシンプルなコマンドではリクエストは送信されなかった。

どうやらバージョンごとに動作が違うらしい。少なくとも2008年2月ごろにリクエストを送信しないように修正された記録がある。

* 2008-02-03: [c1b7382](https://git.savannah.gnu.org/cgit/wget.git/commit/?id=c1b7382ec4c25c23c81a0e0964d94fff72c6a633)でスキップ処理が追加されたっぽい
* 2008-02-06: [cb7d084](https://git.savannah.gnu.org/cgit/wget.git/commit/?id=cb7d0840a0bb0d976fb856fbbc2d424a0b1948a8)でスキップ処理を追加したことがChangeLogとNEWSに記載された

きちんとchangelogが残されていて助かる。

## wgetの`--accept`, `--reject`

ダウンロードするファイルとしないファイルを指定できる。引数に含まれている文字によって挙動が変わる。

* `*`, `?`, `[`, `]`が含まれていればパターン扱い
    * パターンって何って感じがするけど、たぶんグロブ的ななにかだと思う
* そうでなければ後方一致

値によっていい感じに暗黙的に挙動を切り替える仕様は、想定が甘いと「いい感じ」にならなくてユーザーの混乱を招くことがあるが、これは比較的うまくいっているケースのように思える。（でも次に使うときにはルール忘れてるかも）

## wgetでApacheのindexページのソートリンクを無視する

* Apacheのindexページには https://www.redmine.org/releases/?C=N;O=D で名前順ソート、みたいなリンクがついている
* wgetでは`--reject-regex '\?C='`で無視するのが楽そう

## チェックサムファイルの検証

最近のリリースではSHA256のチェックサムファイルが用意されているが、古いリリースにはMD5のチェックサムファイルしかない。SHA256のほうが衝突耐性が高いらしいので、そちらを優先して使うようにしている。

* サブディレクトリに置かれているファイルのチェックサム検証
    * `md5sum -c 0.x/redmine-0.9.0.tar.gz.md5`では以下のようなエラーが出て失敗する。
      ```
      md5sum: redmine-0.9.0.tar.gz: No such file or directory
      redmine-0.9.0.tar.gz: FAILED open or read
      md5sum: WARNING: 1 listed file could not be read
      ```
    * チェックサムファイル内のファイルパスが`redmine-0.9.0.tar.gz`になっているので、`0.x/redmine-0.9.0.tar.gz`ではなく`./redmine-0.9.0.tar.gz`を探しに行ってしまうため。
    * ファイルごとに`pushd`, `popd`でカレントディレクトリを切り替えるくらいしか対策を思いつかなかった。
* 1ファイルごとに`sha256sum`や`md5sum`のプロセスを起動しているのがコスト高そう。

## `no checksum file found`

チェックサムファイルが見つからなかったときのエラーメッセージ。最初は何も考えずに`checksum file is not found`と書いてたんだけど、[md5sumのエラーメッセージ](https://github.com/coreutils/coreutils/blob/6a3d2883fed853ee01079477020091068074e12d/src/md5sum.c#L816)がよさそうだったので真似した。情報量のある単語が先になっているのがいい。

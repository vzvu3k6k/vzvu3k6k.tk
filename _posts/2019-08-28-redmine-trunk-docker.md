---
layout: post
title: RedmineのtrunkのDockerイメージを毎日自動でビルドする
---

なんとなくやってみた。リポジトリは<https://github.com/vzvu3k6k/docker-library-redmine/>にある。

Docker official imageの<https://github.com/docker-library/redmine>をベースにしている。このリポジトリの機能のうち、今回やりたいことに関係するのは以下の2つ。

- `*.template`というのがDockerfileのテンプレートで、`update.sh`を実行すると`Dockerfile`が生成される。
- TravisCIを使っていて、`.travis.yml`の設定に従ってビルドしたDockerイメージに対して簡単なテストを実行している。

## `Dockerfile`を生成するために`*.template`と`update.sh`を編集する

オリジナルのリポジトリではRedmine 3.4とRedmine 4.0に対応するためにテンプレートを使っている。今回はtrunkだけに対応すればいいのでテンプレートは不要だが、4.0-stableや3.4-stableのブランチにもそのうち対応したくなるかもしれないので元の仕組みをそのまま残している。

`update.sh`の書き換えは特に書くほどのこともない。

`*.template`はRedmineのソースのtarballをダウンロードする処理をsvnでcheckoutする処理に置き換えた。いくつか引っかかったことがあるのでメモしておく。

#### 中間証明書問題

`https://svn.redmine.org/`は中間証明書を提供していないらしく、`svn co`するとエラーになる。

HTTPSを諦めてHTTPを使う、証明書の検証をスキップする、証明書を自分でインストールするなどの対応が必要。今回は 
証明書をインストールすることにした。[agileware-jp/redmine-plugin-orb#8](https://github.com/agileware-jp/redmine-plugin-orb/pull/8#pullrequestreview-247391606)の実装内容を使わせてもらっている。

元の実装では証明書の受け渡しにprocess substitutionを使っているが、`Dockerfile`の`RUN`はデフォルトでは`/bin/sh`なのでこの機能が使えなかった。

> The default shell on Linux is `["/bin/sh", "-c"]`
>
> [Docker Documentation](https://docs.docker.com/engine/reference/builder/#shell)

参考: <https://stackoverflow.com/q/41354864>

#### 最新のリビジョン

「リビジョン番号を指定しないときには最新のリビジョンを取得する」という動きにしたかったが、SVNで最新のリビジョンを表すにはどうしたらいいのかわからなくて困った。

パースできないリビジョン番号を指定したときに出てくるエラーメッセージ（`Syntax error in revision argument`）でsvnのソースをgrepして、`svn_opt_parse_revision_to_range`→`parse_one_rev`→`revision_from_word`という感じで関数をたどってみて、`head`という文字列でいけることが分かった。

あとから急に思いついて「svn revision format」でググってみたらドキュメントがあっさりでてきた。

<http://svnbook.red-bean.com/en/1.7/svn.tour.revs.specifiers.html>

よく見たら`svn help co`でも普通に説明されていた。

## `.travis.yml`を編集する

### Dockerイメージのテスト

[docker-library/official-images](https://github.com/docker-library/official-images)にはDockerイメージが意図通りに動くかどうかざっくりテストする仕組みがあって、[docker-library/redmineもそのテストを利用している](https://github.com/docker-library/redmine/blob/62f92a43718f9ead7f404e4584c00735a1cbbed7/.travis.yml#L25)。テストコードはすべてofficial-imagesリポジトリに入っていて、`~/official-images/test/run.sh`にイメージ名を渡すとそのイメージを対象にしたテストが実行される。このとき、[特に設定しなければイメージ名のネームスペースを無視してくれる](https://github.com/docker-library/official-images/blob/af391a3a103b694b81b08e87b17d384a30f1ee44/test/run.sh#L130)ので、`vzvu3k6k/redmine`というようなイメージ名にしておけば何も手を加えなくてもdocker-library/redmineのイメージと同じテストが実行される。これはとても助かった。

### フェーズ間で情報を受け渡す

TravisCIのジョブはいくつかのフェーズに分かれている（参照: <https://docs.travis-ci.com/user/job-lifecycle/>）。今回はそれぞれのフェーズで以下のような処理をしている。

- `before_script`フェーズ: 最新のリビジョン番号を取得する
- `script`フェーズ: そのリビジョン番号のコードを取得してイメージをビルドする
- `deploy`フェーズ: ビルドしたイメージにリビジョン番号のタグをつけて公開する

`before_script`フェーズで定義した環境変数は`script`フェーズからは参照できるが、`deploy`フェーズからは参照できなかった。

フェーズごとに最新のリビジョン番号を取り直せばだいたいうまくいくが、何度もSVNサーバーにリクエストを送りたくはないし、ジョブの実行中にコミットがあるとイメージの中身とタグがずれてしまう可能性がある。

TravisCI側では特に解決策を提供していないようなので、値をファイルに書き出しておくことにした。デフォルトでは`deploy`フェーズの前に`git stash --all`でファイルがリセットされるので設定で無効にしておく必要がある。（参照: <https://docs.travis-ci.com/user/deployment#uploading-files-and-skip_cleanup>）

### シェルスクリプト

細かいところでいろいろ詰まって調べた。

- `puts $stdin.read.slice(/^Revision: (\d+)$/, 1)`相当のことをgrepでサクッと書きたい
    - https://unix.stackexchange.com/q/13466
        - GNU grepなら`grep -o -P "^Revision: \K\d+$"`で近い結果が得られる
        - `-o`でマッチした箇所だけを表示
        - `-P`でPCREを有効にして後読み、先読みを使って不要な箇所を読み捨てる
    - しかしデフォルトの設定ではRubyが使えるっぽいので`grep`使う必要はなかった
- `source`で実行したシェルスクリプトの中で`set`を使うと呼び出し元にも影響する
    - https://superuser.com/q/648331/
        - `SETTING=$(set +o); something; eval "$SETTINGS"`で設定を保存して復元できる
- 実行中のシェルスクリプトと同じディレクトリにあるシェルスクリプトを実行したい
    - https://stackoverflow.com/q/6659689
        - いろいろ方法はあるけど、どれも確実ではない。
        - 今回は`$BASH_SOURCE`を使った。

## 感想など

- 普段はCircleCIを使っていて、TravisCIは軽く触ったことがある程度だった。
    - 見た目はTravisCIのほうが好み。機能面では後発のCircleCIのほうが充実しているように見える。
        - [コンテナにSSHアクセスする機能](https://circleci.com/docs/2.0/ssh-access-jobs/)とか、[手元環境でjobを実行する機能](https://circleci.com/docs/2.0/local-cli/#run-a-job-in-a-container-on-your-machine)とか。
    - CircleCIの[workflow](https://circleci.com/docs/2.0/workflows/)に相当するのは[build stages](https://docs.travis-ci.com/user/build-stages/)だろうか。
        - 処理を並行で進めたり、待ち合わせたりする制御機能。
- Docker HubにpushするときにはアカウントのIDとパスワードが必要だった。
    - CircleCIのENVに設定している。
    - 生のパスワードが漏洩するとアカウントごと乗っ取られてしまうのであまり外部に渡したくないが…
    - トークン的なものはあるようだが有効期間が短いのでCIには使えない。
    - push権限しかないbotユーザーを作るといいよという話があった。なるほど。
        - https://stackoverflow.com/a/41842683
    - 2FAを実装してほしいという要望も前々から上がっているものの進んでいない（<https://github.com/docker/hub-feedback/issues/358>）。開発リソースの問題だろうか。
- Docker Hubにpushするたびにイメージのpull数が増えてる気がする。自動的にイメージを収集するbotかなにかが走っているのだろうか。

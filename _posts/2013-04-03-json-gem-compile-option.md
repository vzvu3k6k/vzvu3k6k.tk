---
layout: post
title: OpenFastLadderをインストールしようとしたらCFLAGSを書き直してJSON gemにpull requestを送ることになった
---

[OpenFastLadder](https://github.com/fastladder/fastladder)をダウンロードして`bundle install`してたらjson 1.7.7のインストールでエラーが出たので原因を調べた。

エラーメッセージは
<pre>
Building native extensions.  This could take a while...
ERROR:  Error installing json:
	ERROR: Failed to build gem native extension.

        /usr/bin/ruby19 extconf.rb
creating Makefile

make
compiling generator.c
cc1: エラー: ‘-O’ への引数は非負整数であるべきです
make: *** [generator.o] エラー 1


Gem files will remain installed in /usr/local/lib/ruby/gems/1.9.1/gems/json-1.7.7 for inspection.
Results logged to /usr/local/lib/ruby/gems/1.9.1/gems/json-1.7.7/ext/json/ext/generator/gem_make.out
</pre>
というもの。エラーメッセージでそのままググってみたけど似た事例が出てこない。

`/usr/local/lib/ruby/gems/1.9.1/gems/json-1.7.7/ext/json/ext/generator/Makefile`を見たらCFLAGSに`-O3fast`というオプションがあった。これがエラーの原因らしい。Makefileは同じディレクトリのextconf.rbというファイルで生成されているようだ。見てみると

    unless $CFLAGS.gsub!(/ -O[\dsz]?/, ' -O3')
      $CFLAGS << ' -O3'
    end

という処理があった。ここで$CFLAGSの`-Ofast`が`-O3fast`に置換されている。

改めてgccのマニュアルを読んでみると、[`-Ofast`](http://gcc.gnu.org/onlinedocs/gcc-4.6.3/gcc/Optimize-Options.html#index-Ofast-686)は`-O3`を有効にしたうえでさらにいくつかの最適化を有効にするというものだった。Gentooのドキュメント（[CFLAGS - Gentoo Linux Wiki](http://en.gentoo-wiki.com/wiki/CFLAGS), [Gentoo Linux ドキュメント -- コンパイル最適化ガイド](http://www.gentoo.org/doc/ja/gcc-optimization.xml)）を読むと、`-O3`はgcc 4.xでは非推奨だし、`-Ofast`で有効になる[`-ffast-math`](http://gcc.gnu.org/onlinedocs/gcc-4.6.3/gcc/Optimize-Options.html#index-ffast_002dmath-847)も、実装がIEEEやISOの数学関数の仕様を順守していることを前提としたコードでは不正な結果を出力する可能性があるので`-O`オプションでは無効にされているとのこと。深く考えずに、なんか早くなりそうだからCFLAGSに入れてしまったが、こちらも軽い気持ちで手を出してはいけない雰囲気のオプションだった。

とりあえず`/etc/make.conf`の`-Ofast`を外して`-Os`に書き換えたが、またしても同じエラーが出る。extconf.rb内の$CFLAGSが書き換わっていない。$CFLAGSを提供しているmkmfのソースを確認すると、$CFLAGSはrbconfigというライブラリから取得していて、これは<q cite="http://rurema.clear-code.com/1.9.3/library/rbconfig.html">Ruby インタプリタ作成時に設定された情報を格納したライブラリ</q>なのだそうだ。rubyを入れ直したら$CFLAGSに変更が反映され、JSON gemのインストールに成功した。

せっかくなのでJSONのextconf.rbを`-Ofast`に対応させてpull requestを送ることにした。[`-O`オプションは最後に指定されたものが有効になる](http://gcc.gnu.org/onlinedocs/gcc-4.6.3/gcc/Optimize-Options.html#index-Ofast-686)ので、`gsub!`を使って置換したり条件分岐したりするのはやめて、何も考えずに`-O3`を付け足すという処理にした。`$CFLAGS`が`-O`オプションで始まってると正常に置換できないという問題もついでに解決できるし、今後gccの`-O`オプションが追加されてもたぶん問題ない。

もうひとつ気になったのが`generator/extconf.rb`の

      unless $DEBUG && !$CFLAGS.gsub!(/ -O[\dsz]?/, ' -O0 -ggdb')
        $CFLAGS << ' -O0 -ggdb'
      end

というコード。$DEBUGがfalseのときにデバッグ用っぽいオプションが追加されている。`parser/extconf.rb`のほうは`if $DEBUG && !$CFLAGS.gsub!(/ -O[\dsz]?/, ' -O0 -ggdb')`になっている。`generator`のほうが条件式を間違えてるようだ。ついでにこれも修正して[pull requestを送ってみた](https://github.com/flori/json/pull/166)。

それにしても、gentooのドキュメントでは<q>プラス面よりもマイナス面が勝っています</q>とまで書かれている`-O3`をJSON gemが有効にしてるのは不思議に思える。日頃からソフトのインストールはほとんどパッケージマネージャーに頼りきりで、自分ではMakefileなどを触ったりしないので事情がよく分からない。[rubyのソース](https://github.com/ruby/ruby)を取ってきて`autoconf;./configure`して生成されたMakefileを見てみると

    CFLAGS = ${cflags} $(ARCH_FLAG)
    cflags =  ${optflags} ${debugflags} ${warnflags}
    optflags = -O3 -fno-fast-math

こうなっていた。`configure`のほうには

    if test "$GCC" = yes; then
        linker_flag=-Wl,
        : ${optflags=-O3}

こんな記述がある。optflagsのデフォルト値を`-O3`にしているらしい。本体が`-O3`を使っている以上、ライブラリが使ってはいけない道理はないが、実際のところどれほど効き目があるのだろうか。

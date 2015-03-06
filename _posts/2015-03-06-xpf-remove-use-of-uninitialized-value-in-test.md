---
layout: post
title: XPathFeedのテスト実行時の"Use of uninitialized value $url ..."を消す
---

[Ensure weak references in use in HTML::TreeBuilder? by vzvu3k6k · Pull Request #5 · onishi/xpathfeed](https://github.com/onishi/xpathfeed/pull/5)についての覚え書き。

t/XPathFeed.tを実行すると
```
Use of uninitialized value $url in pattern match (m//) at lib/XPathFeed.pm line 91.
Use of uninitialized value $url in concatenation (.) or string at lib/XPathFeed.pm line 91.
```
という警告が表示される。これがエラーとまぎらわしいので消したかった。

```perl
sub uri {
    my $self = shift;
    my $url = $self->url;
    $url =~ /http/ or $url = "http://$url"; # line 91
    $self->{uri} ||= URI->new($url)->canonical;
}
```

問題のコードはXPathFeed::uriにあるのだが、XPathFeedのインスタンスを作ってそのまま捨てる（`carton exec -- perl -Ilib -MXPathFeed -e'XPathFeed->new'`）だけでもこの警告が出る。

しかし、インスタンスを初期化するときにuriメソッドが呼ばれているわけではなさそう。

{% raw %}
```perl
sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    return $class->SUPER::new({%args});
}
```
{% endraw %}

親クラスの`use base qw/Class::Accessor::Fast Class::Data::Inheritable/;`あたりが呼び出しているのかな？と思いながら、[caller](http://perldoc.perl.org/functions/caller.html)でuriメソッドの呼び出し元を追ってみると、実はデストラクタが原因だった。

```perl
sub clean {
    my $self = shift;
    $self->tree or return;
    $self->tree->delete;
}

sub DESTROY { # これがデストラクタ
    my $self = shift;
    $self->clean;
}
```

XPathFeedのインスタンスがGCされるとき、`$self->DESTROY`が呼び出され、その中で`$self->clean`が実行される。ここではメモリリークを避けるため、`$self->tree->delete`でHTML::TreeBuilderのインスタンスが持っているHTML要素などを明示的に破棄している。ところが、`$self->tree`は初回実行時に`$self->decoded_content`からHTML::TreeBuilderのインスタンスを遅延初期化するメソッドなので、ここで意図せずtreeが生成されてしまう。treeを生成するために`$self->decoded_content`が呼ばれ、そこから`$self->http_result`が呼ばれ、その中で`$self->uri`が呼ばれているのだった。さらにキャッシュやLWP::UserAgentなども呼び出され、ようやく生成されたtreeは次の行でバサリと切り倒される。

## 解決方法

一番簡単な解決方法は、uriメソッドを`my $url = $self->url || '';`のように書き換えることだろう。しかし、空のインスタンスを破棄するだけで大量のメソッドが無意味に実行される問題は残る。

`XPathFeed->new`に常にダミーのurlパラメータを渡すのも同様。

別の方法として、`$self->tree`で生成されたHTML::TreeBuilderのインスタンスが`$self->{tree}`に保存されるのを利用する手もある。cleanメソッドで直接`$self->{tree}`を参照してやれば、treeを削除するために生成するような無駄はなくなる。とはいえ、内部で使われることを意図した変数に直接アクセスするのは好ましくない気もする。

### 弱い参照

なぜHTML::TreeBuilder::deleteを呼ばないとメモリリークが発生するのかというと、ノードツリーが親子で循環参照しているので、参照カウント方式のGCだとオブジェクトが不要になったことが検出できないからだそうだ。

最近のPerlには弱い参照が実装されていて、Scalar::Util::weakenで指定した参照はカウントされなくなる。実はHTML::TreeBuilderが内部で使っているHTML::Elementでは、Scalar::Util::weakenが存在していれば自動的に弱い参照を使う。これなら`$self->tree->delete`を呼ぶ必要はなくなる。

`use HTML::TreeBuilder 5 -weak;`とオプションを与えてuseすると弱い参照を使うように強制できる（Scalar::Util::weakenが存在しなければエラーが出る）。これならXPathFeed::cleanやDESTROYを削除できる。

---

```perl
sub clean {
    my $self = shift;
    return if HTML::TreeBuilder->Use_Weak_Refs || !$self->tree;
    $self->tree->delete;
}
```

このように弱い参照が有効になっているか確認するコードを入れるだけで済ませることも考えたが、できればコードの量を減らしたい。どうやら弱い参照は5.8あたりから使えるようになったらしいので、この機能が使えることを前提にしてもよさそう。

#### 弱い参照はいつごろからサポートされているのか

perl56deltaにweak referenceが導入されたというアナウンスがある。当時はexperimentalな機能で、Devel::WeakRefを通じて利用することができた。

perl58deltaでScalar::Utilが追加されていて、この中にweakenも入っている（[Scalar::UtilをPerlにバンドルするコミット](https://github.com/perl/perl5/commit/f4a2945e37e7fde9d94fd91ab4bd8581bde8c1ec)）。weakenなどの内部では`SvWEAKREF`が定義されているかチェックしているが、5.8ではsv.hで無条件に定義されている様子で、それ以降のperldeltaにはこの機能を無効化したという記述はないので、5.8以降では常に使える状態なのではないかと思う。

#### 参考

- [HTML::TreeBuilder - Parser that builds a HTML syntax tree - metacpan.org](https://metacpan.org/pod/HTML::TreeBuilder)
  - [HTML::Element - Class for objects that represent HTML elements - metacpan.org](https://metacpan.org/pod/HTML::Element): `-weak`についての説明。
- [Two-Phased Garbage Collection - perlobj 5.8.9](http://perldoc.perl.org/5.8.9/perlobj.html#Two-Phased-Garbage-Collection): perl 5.8.9では普段のGCには参照カウント方式を使い、スレッドが終了するときはマーク・アンド・スイープ方式のGCを行う。最近のバージョンではこのあたりの記述がなくなっているので、今は違う実装になっているのかもしれない。

## useのオプションの伝播

HTML::TreeBuilderで弱い参照を強制するには`use HTML::TreeBuilder 5 -weak;`と指定せよとドキュメントには書いてある。ところが、HTML/TreeBuilder.pmにはuseのオプションを直接チェックする処理はない。`-weak`を実際に解釈しているのはHTML::Elementというモジュールだ。

HTML/TreeBuilder.pmの中では`use HTML::Element ();`とuseに明示的に空リストが渡されていて、`-weak`を引き渡している様子はない。それではどうやって値がHTML::Elementに渡されているのかというと、継承によって実現されている。

`-weak`のようなオプションは`__PACKAGE__->import()`に渡される。HTML::TreeBuilder::importが存在しないので、`our @ISA = qw(HTML::Element HTML::Parser);`で親クラスに設定されているHTML::Elementのimportが呼び出されるという仕組み。

ちなみに最初の`5`というオプションはHTML::TreeBuilderのバージョンが5以上であることを保証させるオプション。これは`__PACKAGE__::VERSION()`に引数として渡されている。デフォルトではベースクラスの<a href="http://perldoc.perl.org/UNIVERSAL.html">UNIVERSAL::VERSION</a>が呼び出され、クラスの`$VERSION`と照らし合わせて、渡されたバージョンより古ければ`die`される。

### 参考

- [perlobj - perldoc.perl.org](http://perldoc.perl.org/perlobj.html#A-Class-is-Simply-a-Package)
- [use - perldoc.perl.org](http://perldoc.perl.org/functions/use.html)

## その他

XPathFeedにプルリク送りまくってたらcollaboratorにしてもらえた。特にGitHubから通知とかはなくて、ある日突然<https://github.com/>のYour repositoriesにonishi/xpathfeedという表示が追加されたという感じだった。

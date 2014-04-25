---
layout: post
title: Tumblrの省メモリーな無限スクロール
---

[無限スクロール](http://netyougo.com/webservice/13825.html)またはauto pagingと呼ばれるUIには、読み終えたコンテンツがどんどん画面の上のほうに溜まっていってメモリーを食い潰すという問題がある。

なかでもTumblrは画像などのコンテンツが多いため、ダッシュボードダイバーたちは[無限Tumblrユーザースクリプト](http://joodle.tumblr.com/post/14352059524/supertumblr)などのユーザースクリプトをインストールして、読み終えたコンテンツを定期的にページ上から自動削除するといった対策を講じていた。

ところが最近のTumblrのダッシュボードでは、ポストが画面外に出るとその中の要素が一時的にページから削除され、画面内に表示されると要素が再度挿入されるようになっている。どうやらこれによって無限スクロールによるメモリーの圧迫が抑えられているらしい。

関連するコードは[https://secure.assets.tumblr.com/assets/scripts/dashboard.js](https://secure.assets.tumblr.com/assets/scripts/dashboard.js)の`/*! scripts/ghostlist.js */`や`/*! scripts/fast_dashboard.js */`の付近にある。具体的には、表示領域から大きく外れたポストの子要素に対して

1. imgのsrcには一時的にダミーのgif画像を入れる
2. DOMノードをクロージャー内の変数に保持して、ページ上からは削除

という処理をしている。表示領域に入ったら、削除していたノードの再挿入などを行なって復元する。そのほかに一時的に退避させたbackground-image属性を復元する関数もあったが、属性を退避させるコードはどこにあるのか分からなかった。再生中の動画や音楽コンテンツについても、再生が終わるまで待たず、普通にページ上から削除しているようだ。

ノードを削除する関数などが、自分の行った処理を復元する関数を返すようになっているのが面白い。ノードをそのまま返すのではなくfunctionで包むぶん、少しだけメモリーを余分に使いそうな気がする。その一方、クロージャーに内包される不要な変数にはこまめにnullを代入してメモリーの浪費を抑えている。

この機能はghostlistという名前で実装されている。"infinite scroll ghostlist"や"auto paging ghostlist"でググってみたが、[atesh/ghostlist · GitHub](https://github.com/atesh/ghostlist/)の他には似たものが見つからない。

## 2番目の処理について

2番目の処理は本当に効果があるのか疑問だったので実験してみた。Chromeのdevtoolのtimelineを使ってメモリーの使用量を確認する。適当なページを開いて、まず`Array.prototype.slice.call(document.querySelectorAll('img'), 0).forEach(function(i){i.remove()})`で画像を消し（1に相当）、GCを走らせる。それから`a = Array.prototype.slice.call(document.body.children, 0).map(function(i){i.remove(); return i})`でbodyの子要素を退避（2に相当）。GCを走らせた直後と子要素を退避させた後のメモリーの使用量の差を確かめる。

<dl>
  <dt><a href="http://www.nicovideo.jp/">http://www.nicovideo.jp/</a></dt>
  <dd><img src="{{ site.baseurl }}img/ghostlist_nicovideo.png"><br>子要素を退避させた直後にはメモリーの使用量が増加しているが、その後しばらくすると退避前よりも使用量が減少している。</dd>
  <dt><a href="http://www.asahi.com/">http://www.asahi.com/</a></dt>
  <dd><img src="{{ site.baseurl }}img/ghostlist_asahi.png"><br>同上。</dd>
  <dt><a href="https://www.google.co.jp/search?q=dom+memory&amp;num=100">https://www.google.co.jp/search?q=dom+memory&num=100</a></dt>
  <dd>何もしていなくてもメモリーの使用量のグラフがきれいなノコギリ波を描く。裏で走っているタイマーが大量にオブジェクトを生成していて、定期的にGCが行われているのではないかと思う。画像を消しても子要素を退避しても、ほとんど変化が見られない。むしろ微妙に使用量が増える。</dd>
  <dt><a href="http://jsfiddle.net/vzvu3k6k/fQce4/">http://jsfiddle.net/vzvu3k6k/fQce4/</a></dt>
  <dd>効果なし。微妙に使用量が増える。</dd>
</dl>

華やかなページでは効果が見られるが、テキスト主体のシンプルなページでは意味がないようだ。

## 関連

* [Infinite Scroll Memory Optimization](http://dannysu.com/2012/07/07/infinite-scroll-memory-optimization/) - 表示領域外の要素を消すというアプローチを取った例。無限スクロールで追加される要素が画像だけなので、画面上からノードを消してJavaScriptの変数として保持するということはしていない。コメント欄に[ソースへのリンク](https://github.com/dannysu/eol-infinite-scroll)がある。
  * ちなみにGoogleの画像検索でも、画面外に出た一部のimg要素のsrc属性を一時的に消しておいて、画面に表示されたらsrcを戻すということをしている。
* [Autopagerize: Delete old pages - Hatena::Let](http://let.hatelabo.jp/vzvu3k6k/let/hLHX5ZrPpLVS) - Autopagerizeで挿入されたページを最後のもの以外全部消すブックマークレット
* [Tumblr: Empty trails on dashboard](https://gist.github.com/vzvu3k6k/11295076)というuserscriptを書いててGhostListの存在に気づいた。
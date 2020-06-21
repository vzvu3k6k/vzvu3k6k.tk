---
layout: post
title: Tumblrの省メモリーな無限スクロール
---

[無限スクロール](http://netyougo.com/webservice/13825.html)またはauto pagingと呼ばれるUIには、読み終えたコンテンツがどんどん画面の上のほうに溜まっていってメモリーを食い潰すという問題がある。

なかでもTumblrは画像などのコンテンツが多いため、ダッシュボードダイバーたちは[無限Tumblrユーザースクリプト](http://joodle.tumblr.com/post/14352059524/supertumblr)などのユーザースクリプトをインストールして、読み終えたコンテンツを定期的にページ上から自動削除するといった対策を講じていた。

ところが最近のTumblrのダッシュボードでは、ポストが画面外に出るとその中の要素が一時的にページから削除され、画面内に表示されると要素が再度復元されるようになっている。どうやらこれによって無限スクロールによるメモリーの圧迫が抑えられているらしい。

関連するコードは[https://secure.assets.tumblr.com/assets/scripts/dashboard.js](https://secure.assets.tumblr.com/assets/scripts/dashboard.js)の`/*! scripts/ghostlist.js */`や`/*! scripts/fast_dashboard.js */`の付近にある。具体的には、表示領域から大きく外れたポストの子要素に対して

1. imgのsrcには一時的にダミーのgif画像を入れる
2. `jQuery.browser.mozilla`が真なら、DOMノードをクロージャー内の変数に保持してページ上からは削除する。偽なら`node.style.display = "none"`で非表示にする。

という処理をしている。表示領域に入ったらノードが復元される。`jQuery.browser.mozilla`が真の場合にはaudioやvideoのポストには処理が行われない。これはスクロールすると動画や音楽が勝手に停止したり、再生位置が失われたりするのを防ぐためだと思う。そのほかに一時的に退避させたbackground-image属性を復元する関数もあったが、属性を退避させるコードはどこにあるのか分からなかった。

ノードを完全に消してしまうよりも賢い解決策だと思うが、読み終わったポストをページ内検索で探すことができなくなるのがちょっと気になる。

実装面では、ノードを隠す関数の返り値が自分の行った処理を復元する関数になっているのが面白い。ノードをそのまま返すのではなくfunctionで包むぶん、少しだけメモリーを余分に使いそうな気がする。その一方、クロージャーに内包される不要な変数にはこまめにnullを代入してメモリーの浪費を抑えている。

この機能はghostlistという名前で実装されているが、一般的な名称ではないらしく、"infinite scroll ghostlist"や"auto paging ghostlist"でググってみても、[atesh/ghostlist · GitHub](https://github.com/atesh/ghostlist/)ぐらいしか見つからなかった。

## 2番目の処理について

2番目の処理は本当に効果があるのか疑問だったので、Chromeのdevtoolのtimelineを使ってメモリーの使用量を確認した。

ただし、

<blockquote>
  <p>display noneするとRenderTreeから要素が消えるからその分はメモリ減るかな。メモリ使用量をどうやって測っているのかきになる。V8ヒープ領域のみ見ているように見える。</p>
  <footer>
    — <a href="http://b.hatena.ne.jp/nyaxt/20140613#bookmark-199467470">b:id:nyaxt:20140613</a>
  </footer>
</blockquote>

とのことで、この方法では正しくメモリーの使用量が測れていないらしい。

### `display = "none"`方式

GCを実行したあと、`document.body.style.display = "none"`や`Array.prototype.forEach.call(document.body.children, function(i){i.style.display = "none"})`などを実行してみたが、特に変化がない気がする。

### ノードを変数で保持してページ上から削除する方式

Firefoxで検証するべきだが、とりあえずChromeを使って調べた。

適当なページを開いて、まず`Array.prototype.slice.call(document.querySelectorAll('img'), 0).forEach(function(i){i.remove()})`で画像を消し（1に相当）、GCを実行する。それから`a = Array.prototype.slice.call(document.body.children, 0).map(function(i){i.remove(); return i})`でbodyの子要素を退避（2に相当）。GCを実行した直後と子要素を退避させた後のメモリーの使用量の差を確かめる。

<dl>
  <dt><a href="http://www.nicovideo.jp/">http://www.nicovideo.jp/</a></dt>
  <dd><img src="/memo/img/ghostlist_nicovideo.png"><br>子要素を退避させた直後にはメモリーの使用量が増加しているが、その後しばらくすると退避前よりも使用量が減少している。</dd>
  <dt><a href="http://www.asahi.com/">http://www.asahi.com/</a></dt>
  <dd><img src="/memo/img/ghostlist_asahi.png"><br>同上。</dd>
  <dt><a href="https://www.google.co.jp/search?q=dom+memory&amp;num=100">https://www.google.co.jp/search?q=dom+memory&num=100</a></dt>
  <dd>何もしていなくてもメモリーの使用量のグラフがきれいなノコギリ波を描く。裏で走っているタイマーが大量にオブジェクトを生成していて、定期的にGCが行われているのではないかと思う。画像を消しても子要素を退避しても、ほとんど変化が見られない。むしろ微妙に使用量が増える。</dd>
  <dt><a href="http://jsfiddle.net/vzvu3k6k/fQce4/">http://jsfiddle.net/vzvu3k6k/fQce4/</a></dt>
  <dd>効果なし。微妙に使用量が増える。</dd>
</dl>

グラフィカルなページではメモリーの使用量を抑える効果が見られるが、テキスト主体のシンプルなページでは意味がないようだ。

## 関連

* [XKit - XKit DashboardGL](http://xkit-extension.tumblr.com/post/61016195061/xkit-dashboardgl) - 2013/09/12の記事。1週間ほど前に、画像を隠すことでスクロールを高速化する機能がTumblrに実装されたと報告している。当時はDashboardGLと呼ばれていたようだ。
* [Infinite Scroll Memory Optimization](http://dannysu.com/2012/07/07/infinite-scroll-memory-optimization/) - 表示領域外の要素を消すというアプローチを取った例。無限スクロールで追加される要素が画像だけなので、画面上からノードを消してJavaScriptの変数として保持するということはしていない。コメント欄に[ソースへのリンク](https://github.com/dannysu/eol-infinite-scroll)がある。
  * ちなみにGoogleの画像検索でも、画面外に出た一部のimg要素のsrc属性を一時的に消しておいて、画面に表示されたらsrcを戻すということをしている。
* [Autopagerize: Delete old pages - Hatena::Let](http://let.hatelabo.jp/vzvu3k6k/let/hLHX5ZrPpLVS) - Autopagerizeで挿入されたページを最後のもの以外全部消すブックマークレット
* [Tumblr: Empty trails on dashboard](https://gist.github.com/vzvu3k6k/11295076)というuserscriptを書いててGhostListの存在に気づいた。
* [無限スクロールの問題点と解決方法 - 記録](http://vzvu3k6k.tk/memo/2014/04/27/better-infinite-scroll.html)

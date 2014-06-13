---
layout: post
title: 無限スクロールの問題点と解決方法
---

無限スクロールとは、ページの下部までスクロールすると自動的に新しい要素が追加される機能のこと。TwitterなどのSNSのタイムラインを初めとして様々なウェブサイトで使われているが、いくつかの問題点も指摘されている。

無限スクロールのよく知られた問題点と、それに対する解決方法をまとめた。

## 別のページに移動してから戻ると継ぎ足しがリセットされる

リンクがクリックされたときは常に新しいウィンドウを開くようにしたり、 [Lightbox](http://www.lokeshdhakar.com/projects/lightbox2/)のようなモーダルな擬似ウィンドウをページ内に開いたりすることで、ページの遷移そのものを抑制するという方法がある。

また、次の項目で紹介する「History APIでURLを書き換える」という方法を使えば、読み進んだ位置は復元される。

## permalinkが取れない

同じページに次々と新しい内容が継ぎ足されていくので、いま自分が見ているページのURLが分からないという問題。

### History APIでURLを書き換える

スクロール位置に応じてHistory APIでURLを書き換える。

[We Heart It](http://weheartit.com/)が実装している。

### リンクを追加する

次のページを追加する際にpermalinkも追加する。

[AutoPagerize](http://autopagerize.net/)（任意のウェブサイトに無限スクロール機能を追加できるブラウザ拡張）はこの方式を取っている。

## ページを飛ばせない

ページの最下部までスクロールすることでしか次のページを表示できない場合、何ページか飛ばして読んだりすることができない。

### ナビゲーションを追加する

[We Heart It](http://weheartit.com/)ではページの右下にこのようなナビゲーションを設けている。テキストボックスにページ番号を入力してEnterを押すとそのページに移動できる。

![]({{ site.baseurl }}img/better-infinite-scroll-navigation.png)

## メモリーが食い潰される

[Tumblrの省メモリーな無限スクロール]({{ site.baseurl }}2014/04/26/tumblr-ghostlist.html)を参照。

## 参考

* [第2回　スクロールとページングのUIを考える（2）：フロントエンドWeb戦略室｜gihyo.jp … 技術評論社](http://gihyo.jp/dev/serial/01/front-end_web/000202?page=2)
* [xkcd: Infinite Scrolling](http://xkcd.com/1309/)

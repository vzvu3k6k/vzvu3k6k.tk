---
layout: post
title: はてなブックマークの「トピック」にAutoPagerizeとLDRizeを適用する
---

- [はてなブックマーク - トピック](http://b.hatena.ne.jp/topiclist)
- [自然言語処理技術を用いたはてなブックマークの新機能「トピック」をベータリリースしました - はてなブックマーク開発ブログ](http://bookmark.hatenastaff.com/entry/2015/02/05/190331)

はてなブックマークで盛り上がった話題をピックアップして、関連記事を提示してくれる機能がベータリリースされた。すでに10年分のトピックがあるので、AutoPagerizeとLDRizeでテンポよく読んでいきたい。

## AutoPagerize

[アイテム: はてなブックマーク - トピック - データベース: AutoPagerize - wedata](http://wedata.net/items/76901)

SITEINFOは追加したが、いくつかのAutoPagerize系の拡張は`http://b.hatena.ne.jp/*`では動作しないように設定されている（[Firefox版AutoPagerize](https://addons.mozilla.org/en-US/firefox/addon/autopagerize/)と[uAutoPagerize](https://github.com/Griever/userChromeJS/tree/master/uAutoPagerize)で確認）ので、トピックリスト関連のページを無効化の対象から外すように書き換える必要がある（[Firefox版AutoPagerizeの書き換え例](https://github.com/vzvu3k6k/autopagerize_for_firefox/commit/2263f5941df30ea6cab0a43f1c4bbe310d088a99)）。はてなブックマークの[ユーザーのブックマーク一覧](http://b.hatena.ne.jp/skozawa/)には無限スクロールが実装されているから、そのうちトピック機能にも実装されるのではないか、ということでプルリクエストは送っていない。

右側の日付リストについては、[継ぎ足したら日付リストも伸ばしていくというユーザースクリプトを書いてみた](https://github.com/vzvu3k6k/b_hatena_topiclist-infinite_scroll.user.js/commit/8e8e8515832c7afc689cbb28875530c342b1415a)が、ページ側のスクリプトでDOMをキャッシュしているので、これだけではスクロールしてもハイライトが変化しない。継ぎ足した時に`unsafeWindow`などを経由してキャッシュを消してやれば動きそうだが、数回継ぎ足しただけでリストが溢れるという問題もある。日付をカレンダーのように並べるとか、表示していない月は折りたたむなどという対策を考えたが、実装が面倒なわりにメリットが少ないのでそのままにしている。

「あとで読む」ボタンはそのままでは有効にならない。ユーザースクリプトなどを使って、`AutoPagerize_DOMNodeInserted`の発火時に[b_hatena_topiclist-expand_topic.user.js/main.user.js#L60-61](https://github.com/vzvu3k6k/b_hatena_topiclist-expand_topic.user.js/blob/cdff45a1c707c48801ce99ff0f28f814dcb0109d/scripts/main.user.js#L60-L61)のような処理を走らせれば動くようになるはず。

## LDRize

- [アイテム: はてなブックマーク - エントリ一覧ページ - データベース: LDRize - wedata](http://wedata.net/items/76903)
- [アイテム: はてなブックマーク - トピック一覧ページ - データベース: LDRize - wedata](http://wedata.net/items/76902)

### トピックを展開するユーザースクリプトとの連携

省略されたタイトルとサムネイルだけではトピックの内容が分からないことがある。その場で内容を確認できると便利かもしれない、と思って[b_hatena_topiclist-expand_topic.user.js](https://github.com/vzvu3k6k/b_hatena_topiclist-expand_topic.user.js)というユーザースクリプトを書いた。トピックにマウスカーソルを当てると、右下にボタンが表示されて、クリックするとトピックが展開される。

LDRizeと書いたけど実際にはLDRizeではなくて[mooz/keysnail · GitHub](https://github.com/mooz/keysnail)の[LDRnail](https://gist.github.com/958/1369730)というプラグインを使っている。[サイトローカル・キーマップ](https://raw.githubusercontent.com/mooz/keysnail/master/plugins/site-local-keymap.ks.js)というプラグインと組み合わせると、手軽にLDRnailにキーバインドを追加するようなことができる。

以下のコードをKeySnailの設定ファイルに追加すると、LDRnailで選択中のトピックを<kbd>i</kbd>キーで展開できるようになる。

```js
local["^http://b.hatena.ne.jp/topiclist"] = [
  ['i', function (){
    var open = plugins.ldrnail.currentItem.querySelector('.__expand-button');
    if(open){
      open.click();
    }
  }],
];
```

ただ、手元の環境だと<kbd>i</kbd>を押してから概要を開くのに数秒かかる。普通に開いてタブを切り替えながら読んだほうがいいような気がしてきた。

## SITEINFO雑感

CSS selectorの`.class-name`に相当するXPathは、厳密に書くと`*[contains(concat(" ", normalize-space(@class), " "), " class-name ")]`となる（参考: [SITEINFO中のnormalize-space()削除について - 枕を欹てて聴く](http://constellation.hatenablog.com/entry/20080530/1212161519)）のだが、他のSITEINFOを見てみると`//a[@class='class-name']`という感じで簡便に指定しているものが多い。厳密な書き方だと視認性が下がるし、SITEINFOファイルが肥大化するのを避けるという意味もあるのかもしれない。

トピック機能はまだベータ版なので、class属性を完全一致で指定するよりもCSSのclass selector相当の記法を使って変更に強くしたほうがいいのでは、と思ったけど、<abbr title="You aren't gonna need it.">YAGNI</abbr>という気もする。

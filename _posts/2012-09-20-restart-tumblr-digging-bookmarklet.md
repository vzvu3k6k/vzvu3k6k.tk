---
layout: post
title: Tumblrのダッシュボードとかで潜った位置を記録して再開するブックマークレット
---

## 追記（2013/06/09）
アップデートしたものをHatena::Letに置いた。[Tumblr dashboard bookmark - Hatena::Let](http://let.hatelabo.jp/vzvu3k6k/let/gYC-x-Tt9cbcYQ)

---

[僕は"あした"から"ホンキ"をだす, ある時刻のdashboardに戻る方法](http://cineraria.tumblr.com/post/31330063418/dashboard "僕は"あした"から"ホンキ"をだす, ある時刻のdashboardに戻る方法")に触発されて<a href="javascript:(function()%7Bvar%20c%3Ddocument.viewport.getScrollOffsets().top%2Cb%3D%24%24('%23posts%20.post%5Bid%5E%3D%22post_%22%5D').detect(function(a)%7Breturn%20Element.cumulativeOffset(a).top%3Ec%7D)%2Ca%3DparseInt(b.id.replace(%22post_%22%2C%22%22)%2C10)%2B1%2Ca%3Dwindow.next_page.replace(%2F%5Cd%2B%24%2F%2C%22%22)%2Ba%2Cd%3Da.replace(%2F%5Ehttp%3A%5C%2F%5C%2Fwww%5C.tumblr%5C.com%5C%2F%2F%2C%22%22)%2Ca%3D(new%20Element(%22a%22%2C%7Bhref%3Aa%7D)).update(d)%3Bb.insert(%7Btop%3Aa%7D)%7D)()">ブックマークレット</a>を作った。開くと今読んでいるポストの上部にリンクが追加される。そのリンクをブックマークしておくと、そこからダッシュボード潜りを再開できる。auto pagingする場所ではだいたい動くので、タグ検索画面([http://www.tumblr.com/tagged/bookmarklet](http://www.tumblr.com/tagged/bookmarklet))とかでも使える。

元ソースは以下。Tumblrで使われているprototype.jsに依存している。[Tumblr Tornado](http://userscripts.org/scripts/show/137667 "Tumblr Tornado for Greasemonkey")や、Tumblrの`start_observing_key_commands`関数を参考にした。

<pre>
<code>
(function(){
    var currentPosition = document.viewport.getScrollOffsets().top;
    var currentPost = $$('#posts .post[id^="post_"]').detect(function(post){
        return Element.cumulativeOffset(post).top > currentPosition;
    });

    var id = (parseInt(currentPost.id.replace("post_", ""), 10) + 1),
        href = window.next_page.replace(/\d+$/, "") + id,
        label = href.replace(/^http:\/\/www\.tumblr\.com\//, ""),
        link = new Element('a', {href: href}).update(label);
    currentPost.insert({top: link});
})();
</code>
</pre>

ダッシュボードだけで動作するバージョンを作ってから[Userscripts.org](http://userscripts.org/ "Userscripts.org: Power-ups for your browser")を眺めてみたら似たスクリプトがあった。

  - [Tumblr Dashboard Marker](http://userscripts.org/scripts/show/21790 "Tumblr Dashboard Marker for Greasemonkey")
  - [Tumblr Dashboard Bookmarker](http://userscripts.org/scripts/show/77050 "Tumblr Dashboard Bookmarker for Greasemonkey")
  - [Tumblr Bookmarker](http://userscripts.org/scripts/show/94042 "Tumblr Bookmarker for Greasemonkey")

はじめの2つはブックマークしたところまでひたすらスクロールしてロードしつづける方式。

最後の[Tumblr Bookmarker for Greasemonkey](http://userscripts.org/scripts/show/94042 "Tumblr Bookmarker for Greasemonkey")は'http://www.tumblr.com/dashboard/1000/' + ブックマークしたID + '?lite'に移動する方式。ポスト上部のブックマークボタンをクリックするとサイドバーのリストに日時付きでブックマークが追加されるようになっている。リッチ。`@match`に`http://www.tumblr.com/tagged*`なども含まれているからタグ検索画面でも使えそうに思えるが、ダッシュボード用のリンクしか生成されない。作者は自作のTumblr用ユーザースクリプトをまとめた[Missing e](http://missing-e.com/ "Missing e - The original browser extension for Tumblr!")という拡張を公開しており、こちらでは改善されているのかもしれない。試していない。

また、[Tumblr Tornado](http://userscripts.org/scripts/show/137667 "Tumblr Tornado for Greasemonkey")は単体で複数の機能を提供するユーザースクリプトだが、auto pagingするとロケーションバーを書き換える機能がある。潜っている位置を保存したければ何も考えずにブックマークするだけでいい。上記のブックマークレットをダッシュボード以外で動作させるにあたって、Tumblr Tornadoの`enhistory`関数が参考になった。

というわけで、わざわざ作る必要もなかった気がしないでもないが、作ってしまったので公開する。ユーザースクリプトをインストールするのが面倒な人とかには需要があるかもしれない。

## 関連
* [vzvu3k6k/tumblr-set_dashboard_permalink_as_scroll.user.js - GitHub](https://github.com/vzvu3k6k/tumblr-set_dashboard_permalink_as_scroll.user.js) - スクロールに応じてダッシュボードのpermalinkをlocationに設定するユーザースクリプト

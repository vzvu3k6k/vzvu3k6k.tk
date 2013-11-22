---
layout: post
title: SlideShareのスライドをタイル状に表示するユーザースクリプトを作った
---

[vzvu3k6k/slideshare-tileview.user.js · GitHub](https://github.com/vzvu3k6k/slideshare-tileview.user.js)

<a href="http://www.slideshare.net/Erdbeervogel/coaching-for-life-aka-agile-coaching-sure-thing-what-about-life-coaching-in-agile-thinking">
  <img alt="高度に発達したパワーポイントはスタイリッシュ写真集と区別がつかない。" src="{{ site.baseurl }}img/slideshare-tileview.png" class="thumbnail">
</a>

スライドをざっと見渡すのに便利。右下のボタンをクリックするとタイル表示モードになる。スライドをクリックすると通常のモードで見れる。

ボタンのアイコンはどうしようかと思ったけど、Unicodeの文字一覧みたいなページを見てたらそれっぽい文字があったので、それを使うことにした。

ページ数を変更するテキストボックスをクリックしたらなぜかトグルボタンも押されたことになるバグが出て、てっきりSlideShare側のスクリプトが悪さをしてるんだと思ってたけど、
トグルボタンじゃなくて親要素にイベントハンドラを設定していたのが原因だった。「SlideShareのスクリプトが変な動きをする」とかコミットメッセージに書いたままpushするところだった。

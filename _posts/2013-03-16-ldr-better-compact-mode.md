---
layout: post
title: Livedoor Readerの本文非表示モードを改善するユーザースタイルシートとユーザースクリプト
---

[Livedoor Reader: Title-only compact mode - Themes and Skins for Livedoor - userstyles.org](http://userstyles.org/styles/84533/livedoor-reader-title-only-compact-mode)

<dl>
  <dt>Before</dt>
  <dd><img alt="default image" style="max-width: 70%" src="{{ site.baseurl }}img/ldr-title-only-mode-default.png"></dd>
  <dt>After</dt>
  <dd><img alt="demo image" style="max-width: 70%" src="{{ site.baseurl }}img/ldr-title-only-mode-custom.png"></dd>
</dl>

タイトル以外をばっさり消して、文字のサイズをいじったりすると一覧性が上がって見やすくなった。

ちなみにGoogle Readerのヘッドラインモードはこんな感じ。

<img style="max-width: 70%" alt="Google Reader image" src="{{ site.baseurl }}img/ldr-title-only-mode-google-reader-listview.png">

タイトルの横に記事の冒頭の文章が並んでいるのが便利。CSSを使って再現しようとしてみたがどうにもならなかった。Google Readerは`<span class="snippet">`という専用の要素を用意しているようだ。

ついでにフィードごとに表示モードを覚える機能をつけたユーザースクリプトも書いた。[vzvu3k6k/LDR-Title-Only-Mode](https://github.com/vzvu3k6k/LDR-Title-Only-Mode)。

[reader_main.0.3.6.js](http://reader.livedoor.com/js/reader_main.0.3.6.js)の`Control.compact()`（1518行目）と["HatebuComment on LDR" - Userscripts.org](http://userscripts.org/scripts/review/34576)を参考にした。

あとで`Control.title_only`が別のキーに割り当てられたとき`"タイトル以外を非表示にしました。" + TITLE_ONLY_KEY + "で元に戻ります"`の`TITLE_ONLY_KEY`が書き換わらないのがちょっと気になる。

## 参考
[Googleリーダーの代替サービスを試してみたけれどダメだった話](http://digimaga.net/2013/03/only-one-google-reader)

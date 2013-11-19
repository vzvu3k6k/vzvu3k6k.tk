---
layout: post
title: Ruby ToolboxでプロジェクトのREADMEをその場で開くユーザースクリプト
---

[vzvu3k6k / ruby-toolbox-show-readme.user.js](https://github.com/vzvu3k6k/ruby-toolbox-show-readme.user.js)

<img src="{{ site.baseurl }}/img/ruby-toolbox-show-readme-image.png">

Rubyのライブラリをジャンルごとに分類して人気順に配列している[The Ruby Toolbox](https://www.ruby-toolbox.com/)。便利なんだけど、ライブラリの説明文が大雑把すぎてそれぞれの違いがよく分からないことがある。READMEをその場で読めれば便利なのではないかと思って作った。虫眼鏡アイコンをクリックすると、GithubのAPIでリポジトリからREADMEが取得され、挿入される。

READMEは[GithubのAPI](http://developer.github.com/v3/repos/contents/)でHTMLに変換されたものをそのままページ内に追加している。HTMLにJavaScriptが混入されないように配慮されてはいるが（[scriptタグ、onerror="alert(1)"、<a href="javascript:...">などはHTML化で消される](https://github.com/vzvu3k6k/Spoon-Knife/blob/fb6b9709e13b75e03c13c76302c7fe020d1ef83a/README.md)）、もしかしたら抜け道があるかもしれない。

`pre`タグの1行あたりの字数が多いと横方向にはみ出してしまう。折り返したり、表示域を制限して横スクロールしないと見れないようにすると不便なのでそのままにした。

RubygemやGithubのセクションの右上の虫眼鏡アイコンにポインタを乗せると依存情報やコントリビューターの一覧などが出てくることに、このスクリプトを書いていて初めて気づいた。最初、あるプロジェクトだけgemの依存関係とかが表示されていて（たまたまポインタが虫眼鏡の上を通ったらしい）、「なんでこいつだけこんな情報が出てるんだ？」としばらく悩んだ。READMEの読み込みはやや重い処理だと思うので、マウスオーバーではなくクリックで実行されるようにしている。

---
layout: post
title: TwitterやFacebookのアイコンを画像検索してヒット数とかを表示するユーザースクリプト
---

元ネタ：
<blockquote class="twitter-tweet" lang="ja"><p>TwitterのアイコンやFacebookプロフィールをGoogle画像検索とかして、有名人の写真や既存の画像を丸パクリしているかどうか検索結果数を表示する拡張機能とかあればいいのか</p>&mdash; ǝunsʇo ıɯnɟɐsɐɯさん (@otsune) <a href="https://twitter.com/otsune/status/239945208232546304" data-datetime="2012-08-27T04:39:30+00:00">8月 27, 2012</a></blockquote>

TwitterやFacebookのユーザーページにアクセスすると、そのユーザーのアイコンをGoogleで画像検索して検索結果数を表示する。「この画像の最良の推測結果」があればそれも表示する。

動作している様子はこんな感じ。"約 15,200 件"とかいうのが検索結果数で、括弧内が「この画像の最良の推測結果」。

  * ![Twitter @twitter]({{ site.baseurl }}/img/avatar_image_search_userjs_tw-twitter.png)
  * ![Facebook Japan]({{ site.baseurl }}/img/avatar_image_search_userjs_fb-facebookjapan.png)

----

  * 検索結果はGM_*Value()でキャッシュしている。
    * キャッシュにアクセスしてみて古かったら消すだけなので、一度見ただけのユーザーのキャッシュなども際限なく蓄積される。cache.clear()とかabout:configを利用して適宜消してください。
    * sessionStorageを使うつもりだったが、same-originな他のスクリプト（ページ内のスクリプトや他のユーザースクリプト）からも読み書きできるのが気になったのでやめた。
    * sessionStorageを使う場合は<pre><code>var cache = {get: function(k){sessionStorage.getItem(prefix + k)}, set: function(k, v){sessionStorage.setItem(prefix + k, v)}};</code></pre>などと書き換えてください。
  * siteを編集すればTwitterやFacebook以外でも動くようにできるはず。
  * GM_xmlhttpRequest()を使ってクロスドメイン通信をしているので、Firefox + Greasemonkeyの環境以外ではおそらく動かない。
    * GM_*と同様の動きをするラッパーとかを用意してmanifest.jsonなどを書けばGoogle Chromeでも動かせると思う。
  * 検索結果を受け取るコールバック関数に、検索結果を挿入するために必要な情報を渡すあたりが綺麗に書けなかった。putResult, handleSearchResult.bind(this, putResult)のあたり。
 
----

<pre><code>
// ==UserScript==
// @name            Avatar Image Automatic Search
// @description     Search avatar images in Google
// @version         0.1
// @license         public domain
// @match           https://twitter.com/*
// @match           http://www.facebook.com/*
// @match           https://plus.google.com/*
// ==/UserScript==

var site = [{url: /^https?:\/\/twitter\.com\/\w+\/?$/,
             avatarSelector: ".avatar.size128",        // avatar img
             resultSelector: ".profile-card-inner"},   // append result here
            {url: /^https?:\/\/www\.facebook\.com\/\w+\/?$/,
             avatarSelector: ".profilePic img",
             resultSelector: ".name h2"},
            {url: /^https?:\/\/plus.google.com\/\d+\/posts\/?$/,
             avatarSelector: ".l-tk",
             resultSelector: ".KC"}];

var cache = {
    lifetime: 86400000, // millsecond (86400000 ms = 1 day)
    get: function(key){
        var t = GM_getValue(key + "_time");
        if(t === undefined) return;
        if(cache.lifetime < new Date - (+t)){
            GM_deleteValue(key);
            GM_deleteValue(key + "_time");
        }else{
            return GM_getValue(key);
        }
    },
    set: function(key, value){
        GM_setValue(key, value);
        GM_setValue(key + "_time", +new Date + ""); // 大きな数値を入れると失敗するらしいので文字列に変換して保存
    },
    clear: function(){  // use manually
        for(var key in GM_listValues())
            GM_deleteValue(key);
    }
};

if(GM_getValue("noCache")){
    cache.get = cache.set = function(){};
    cache.clear();
}

for(var i = 0, l = site.length; i < l; i++){
    if(site[i].url.test(location.href)){
        var avatarElement = document.querySelector(site[i].avatarSelector);
        if(!avatarElement) continue;
        var avatarUrl = URLabsolutify(avatarElement.src);

        var resultContainer = document.createElement("div");
        resultContainer.id = "avatar_image_search_user_js_result";
        document.querySelector(site[i].resultSelector).appendChild(resultContainer);

        function putResult(result){
            resultContainer.appendChild(result);
            cache.set(avatarUrl, resultContainer.innerHTML);
        }

        var resultHtml = cache.get(avatarUrl);
        if(resultHtml){
            resultContainer.innerHTML = resultHtml;
        }else{
            var searchUrl = "https://www.google.com/searchbyimage?image_url="
                + encodeURIComponent(avatarUrl);
            GM_xmlhttpRequest({url: searchUrl, method: "GET", 
                               onload: handleSearchResult.bind(this, putResult),
                               onerror: handleSearchError.bind(this, putResult)});
        }
        break;
    }
}

function URLabsolutify(url){
    var a = document.createElement("a");
    a.href = url;
    return a.href;
}

function handleSearchResult(putResult, response){
    if(!response.responseXML)
        response.responseXML = new DOMParser().parseFromString(response.responseText, "text/html");

    var hitNum = response.responseXML.querySelector("#resultStats");
    var imageSearchLink = document.createElement("a");
    imageSearchLink.href = response.finalUrl;
    imageSearchLink.textContent = hitNum ? hitNum.firstChild.textContent : "アバター検索：件数取得失敗";

    var guess = response.responseXML.querySelector('a[style="font-weight:bold;font-style:italic"]');
    if(guess){
        var guessLink = document.createElement("a");
        guessLink.href = "https://www.google.com" + guess.href;
        guessLink.textContent = "(" + guess.textContent +")";
    }

    var result = document.createDocumentFragment();
    result.appendChild(imageSearchLink);
    if(guessLink) result.appendChild(guessLink);
    putResult(result);
}

function handleSearchError(putResult, response){
    var result = document.createElement("a");
    result.textContent = "アバター検索失敗";
    result.href = response.finalUrl;
    putResult(result);
}
</code></pre>

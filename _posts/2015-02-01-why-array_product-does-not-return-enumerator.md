---
layout: post
title: 「Effective Rubyのcatch/throwをproduct/findで書き換える」の感想
---

[Effective Rubyのcatch/throwをproduct/findで書き換える - Qiita](http://qiita.com/jnchito/items/2ef9cda52e87b58e6bf0)を読んだ。

```rb
match = catch(:jump) do
  @characters.each do |character|
    @colors.each do |color|
      if player.valid?(character, color)
        throw(:jump, [character, color])
      end
    end
  end
end
```

というコードは

```rb
match = @characters.product(@colors).find {|params| player.valid?(*params) }
```

とリファクタリングできるという話。

<q cite="http://qiita.com/jnchito/items/2ef9cda52e87b58e6bf0#comment-c2dc7ecdbf3c94591291">配列が大きいようだと、product で大量の Array が作られることになるので throw-catch のコードのほうが効率的</q>と[コメント](http://qiita.com/jnchito/items/2ef9cda52e87b58e6bf0#comment-c2dc7ecdbf3c94591291)で指摘されている。

`Array#product`や`catch`/`throw`を使わず、`find`と`break`を使って書いてみたのが以下。

```rb
match = @characters.find {|character|
    valid_color = @colors.find {|color|
        player.valid?(character, color)
    }
    break [character, valid_color] if valid_color
}
```

`Array#product`版に比べるとメモリの消費量は少ないはずだが、これだと`catch`/`throw`を使ったバージョンのほうが分かりやすい。

## `Array#product`にブロックを渡す

`Array#product`にブロックを渡すと、組み合わせを一つごとにブロックの引数にして呼び出してくれるので、次のようにも書ける。

```rb
match = @characters.product(@colors){|params|
    break params if player.valid?(*params)
}

# `break`が実行されなかったときには`match == @characters`になるので、それをチェックする必要がある。
match = nil if match == @characters
```

CRubyの実装を見てみると、ブロックが渡されているときには組み合わせを一つ生成するごとにブロックを呼んでいるようだから、`find`と`break`を使ったバージョンと同じ程度の効率で動くことが期待できる。

また、`Object#to_enum`を使うと

```rb
match = @characters.to_enum(:product, @colors).find {|params| player.valid?(*params) }
```

と書ける。見た目は`product`/`find`版に近い。

ただし、Rubiniusの実装では`Array#product`はブロックの有無に関わらず、結果を一括して生成してしまう。やはり`catch`/`throw`を使ったほうが安全だ。

## `Array#product`はなぜEnumeratorを返さないのか

`Array#combination`や`Array#permutation`などはブロックを渡さずに呼び出すとEnumeratorを返す。なぜ`Array#product`だけがArrayを返すのかよく分からない。

`Enumerator#zip`もEnumeratorではなくArrayを返す。self以外の要素が関わっているのが問題なんだろうか。

RubyのChangelogをgrepしてみたがよく分からない。とりあえず、rb_ary_(combination|product|permutation)が追加されたのはSat Sep 29 17:31:04 2007のことらしい。

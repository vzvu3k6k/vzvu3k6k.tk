---
layout: post
title: system specのexampleの終了時に自動でスクリーンショットを撮る
---

という要件があった。以下のコードで実現できる。

```rb
# spec/support/take_screenshot_after_examples.rbとかに書いてrequireしておく
module TakeScreenshotAfterExamples
  extend ActiveSupport::Concern

  included do
    after do
      page.save_screenshot
    end
  end
end

# spec/rails_helper.rb
RSpec.configure do |config|
  config.include TakeScreenshotAfterExamples, type: :system
end
```

## うまくいかない方法

以下のような実装だと、（少なくともSeleniumのChromeとFirefoxのドライバーでは）真っ白なスクリーンショットが保存されてしまう。

```rb
RSpec.configure do |config|
  config.after type: :system do
    page.save_screenshot
  end
end
```

これは[rspec-railsの`SystemExampleGroup`のafterフック](https://github.com/rspec/rspec-rails/blob/v4.0.1/lib/rspec/rails/example/system_example_group.rb#L107)が上記のフックよりも先に実行されて、その中（114行目）で`Capybara.reset_sessions!`が呼ばれてしまうため。

RSpecのafterフックは、コンテキストの内側から順に、セットされたのとは逆順に呼ばれる。

https://rubydoc.info/gems/rspec-core/RSpec/Core/Hooks#after-instance_method

SystemExampleGroupの実装では、`RSpec.describe '...', type: :system`のコンテキストで`after`ブロックを呼んだのと同じ扱いになる。このコンテキストは`RSpec.configure`よりも「内側」にあたるので、`Capybara.reset_sessions!`が`page.save_screenshot`よりも先に実行されてしまう。

`SystemExampleGroup`と同じ方法を使えば、同じコンテキストで後にセットできるので、`Capybara.reset_sessions!`が呼ばれる前にスクリーンショットを撮ることができる。

## `Capybara.reset_sessions!`を呼ぶと何が起きるか

厳密には、`Capybara.reset_sessions!`を呼んだあとで画面が真っ白になるかどうかはドライバーの実装に依存する。

`reset_sessions!`の呼び出し先を追っていくと`driver.reset!`に行きつくが、このメソッドでブラウザの状態の初期化が行われている。Seleniumのドライバーごとの実装は以下。

- Chrome: https://github.com/teamcapybara/capybara/blob/3.32.2/lib/capybara/selenium/driver_specializations/chrome_driver.rb#L38
- Firefox: https://github.com/teamcapybara/capybara/blob/3.32.2/lib/capybara/selenium/driver_specializations/firefox_driver.rb#L41
  - https://github.com/teamcapybara/capybara/blob/3.32.2/lib/capybara/selenium/driver.rb#L129
    - https://github.com/teamcapybara/capybara/blob/3.32.2/lib/capybara/selenium/driver.rb#L463

大まかには、ストレージをクリアして、ウィンドウを1つだけ残して、`about:blank`を開くといった動作をしている。

## `Capybara.reset_sessions!`は二度呼ばれる

前述の[rspec-railsの`SystemExampleGroup`](https://github.com/rspec/rspec-rails/blob/v4.0.1/lib/rspec/rails/example/system_example_group.rb#L114)のほかに、[capybaraの`rspec.rb`](https://github.com/teamcapybara/capybara/blob/3.32.2/lib/capybara/rspec.rb#L18)でもコールバックをセットしているので、テストケース終了後に`Capybara.reset_sessions!`は二度呼ばれる。

二度呼ぶ必要はなさそうだし、capybaraの`rspec.rb`のほうは消してもいいのではと思ったが、feature specにはrspec-railsから`Capybara.reset_sessions!`を呼ぶ処理がないので、単純に消すと既存のfeature specが壊れてしまうようだ。

## `Capybara.reset_sessions!`の不可解に見えたふるまいについて

`Capybara.reset_sessions!`を上書きして実行をスキップするとスクリーンショットが撮れるのは前もって教えてもらっていたので、以下のような感じでパッチして呼び出し順を調べたりしていた。

```rb
# rails_helper.rb
Capybara.singleton_class.prepend(Module.new {
  def reset_sessions!
    puts '--- reset_sessions! ---'
    super
  end
})

RSpec.configure do |config|
  config.after type: :system do
    puts '--- save_screenshot ---'
    page.save_screenshot
  end
end
```

これは以下のような結果になる。

```
$ bundle exec rspec
--- save_screenshot ---
--- reset_sessions! ---

Finished in 2.49 seconds (files took 0.77894 seconds to load)
1 example, 0 failures
```

この結果からすると、`reset_sessions!`は`save_screenshot`のあとに呼ばれている。

しかし、`reset_sessions!`のパッチに`super`を含めているときだけ（つまり本来の`reset_sessions!`の処理を呼び出しているときだけ）、スクリーンショットが真っ白になることがわかった。あとから呼び出された`Capybara.reset_sessions!`が前の`save_screenshot`の実行結果に影響を与えているように見える。

テストケースの中で`save_screenshot`を呼ぶと`reset_sessions!`のパッチと関係なく常に正常なスクリーンショットが撮影できるのと考え合わせると、テストケースの終了後に実行される何らかの処理を通過すると、`reset_sessions!`が過去に呼び出された`save_screenshot`に影響を与えるようになるのか……？

と思ったが実際にはそんなことはなく、

- 前述のように`Capybara.reset_sessions!`は二度呼ばれる。capybaraは`rails_helper.rb`と同じ`RSpec.configure`のコンテキストで、先にコールバックをセットしているので、`rails_helper.rb`のコールバックよりも後に呼ばれる。
- [rspec-railsの`SystemExampleGroup`のフック](https://github.com/rspec/rspec-rails/blob/v4.0.1/lib/rspec/rails/example/system_example_group.rb#L109)は`$stdout`を一時的に`StringIO`のインスタンスに置き換えているので、`puts`の出力が横取りされる。

というのが理由だった。`$stdout`の置き換えがなければ以下のように出力される。

```
--- reset_sessions! ---
--- save_screenshot ---
--- reset_sessions! ---
```

最初の`reset_sessions!`でブラウザがリセットされているので真っ白なスクリーンショットが撮れてしまうというだけの話だった。

わかってしまえば簡単な話だが、pry-byebugで実行を追いかけるまで見当がつかず、かなり混乱していた。

ところで、`$stdout`が上書きされているので`binding.irb`のREPLではコードの実行結果が飲み込まれてしまうのだけども、`binding.pry`のREPLではコードの実行結果が正しく表示された。何か特別な対応をしているのだろうか。

## 所感

類似の話題として、テストケースの終了後に`Capybara.reset_sessions!`が呼ばれるのを抑制したいという記事があった。

https://gongo.hatenablog.com/entry/2014/09/03/212513

この記事では`Capybara.reset_sessions!`を上書きして無効化している。既存のメソッドの上書きを避けるとしたら、フックのインスタンス変数を直接いじって削除するような方法を取るしかないのではないか。

フック的なAPIはRSpecに限らずいろいろなところで使われているけれども、「すでにセットされているコールバックの振る舞いを変える」というのが難しくなりがちで、今回のように実行順を意識した遠回りな実装が必要になったり、コールバックで呼ばれるメソッドを上書きしたりといったハックを使わなければ対処できないことが多い。

ではどうすればいいのか、というのはよくわからない。コールバックを操作するためのAPIを用意すれば多少楽になるのだろうが、操作対象のコールバックを特定するための情報が必要になる（たとえばJavaScriptの`removeEventListener`ではコールバック関数そのものを引数に受け取る）。Rubyでは匿名のブロックでコールバックをセットすることが多いので、あまり現実的ではないように思う。

## 1. 概要とファイル構成

`hump.class` は、LÖVE（Love2D）などのLua環境でオブジェクト指向プログラミング（クラスの定義や継承）をシンプルに実現するためのライブラリです。

本稿では、ベースとなるスーパークラス（親クラス）と、それを継承するサブクラス（子クラス）を**別々のファイルに分割して定義・管理する方法**について解説します。

### ファイル構成例

* `libs/hump/class.lua` （ライブラリ本体）
* `entity.lua` （親クラス：位置情報などを保持）
* `player.lua` （子クラス：親を継承し、プレイヤー固有の処理を追加）
* `main.lua` （実行ファイル）

---

## 2. スーパークラス（親クラス）の定義

まずは基盤となる親クラス `Entity` を作成します。
`hump.class` では、`Class{}` を実行することで新しいクラスオブジェクトを生成します。コンストラクタは `init` という名前の関数で定義します。

### entity.lua

```lua
-- hump.class の読み込み（パスは環境に合わせて調整してください）
local Class = require("libs.hump.class")

-- Entity クラスの定義
local Entity = Class{}

-- コンストラクタ（初期化処理）
function Entity:init(x, y)
    self.x = x or 0
    self.y = y or 0
end

-- 共通メソッドの定義
function Entity:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

function Entity:draw()
    -- 親クラスのデフォルト描画処理（白い四角形）
    love.graphics.rectangle("solid", self.x, self.y, 32, 32)
end

-- 外部ファイルから読み込めるようにクラスを返す
return Entity

```

---

## 3. サブクラス（子クラス）への継承

次に、`Entity` クラスを継承した `Player` クラスを作成します。
`hump.class` で継承を行うには、**`Class{ __includes = 親クラス }`** という構文を使用します。

また、子クラスのコンストラクタ内で親クラスのコンストラクタを呼び出す（`super` 相当の処理）場合は、**`親クラス.init(self, 引数...)`** と明示的に呼び出す必要があります。

### player.lua

```lua
local Class = require("libs.hump.class")
-- 親クラスのファイルを読み込む
local Entity = require("entity")

-- Entity クラスを継承して Player クラスを定義
local Player = Class{
    __includes = Entity
}

-- コンストラクタ
function Player:init(x, y, speed)
    -- 親クラス（Entity）のコンストラクタを明示的に呼び出す
    Entity.init(self, x, y)
    
    -- 子クラス固有のプロパティ
    self.speed = speed or 200
end

-- メソッドのオーバーライド（上書き）
function Player:draw()
    -- プレイヤー固有の描画（青い四角形）
    love.graphics.setColor(0, 0, 1)
    
    -- 必要に応じて親クラスのメソッドを直接呼び出すことも可能
    -- Entity.draw(self) 
    
    love.graphics.rectangle("solid", self.x, self.y, 32, 32)
    love.graphics.setColor(1, 1, 1) -- 色を白に戻す
end

-- 外部ファイルから読み込めるようにクラスを返す
return Player

```

---

## 4. 実行環境での呼び出し

作成したクラスファイルを `main.lua` で読み込み、インスタンス化して使用します。子クラスのインスタンスは、親クラスから継承したメソッド（例: `move`）をそのまま実行できます。

### main.lua

```lua
local Player = require("player")

local myPlayer

function love.load()
    -- Player クラスのインスタンス化
    -- 引数: x, y, speed
    myPlayer = Player(100, 100, 300)
end

function love.update(dt)
    -- 親クラス（Entity）から継承した move メソッドの実行
    if love.keyboard.isDown("right") then
        myPlayer:move(myPlayer.speed * dt, 0)
    end
    if love.keyboard.isDown("left") then
        myPlayer:move(-myPlayer.speed * dt, 0)
    end
end

function love.draw()
    -- 子クラス（Player）でオーバーライドした draw メソッドの実行
    myPlayer:draw()
end

```

---

## 5. テクニック・注意点まとめ

* **コンストラクタ連動（`__includes` の仕様）**
`hump.class` では、子クラスに `init`（コンストラクタ）を定義しなかった場合、自動的に親クラスの `init` が呼ばれます。しかし、**子クラスで `init` を定義した場合は親の `init` は自動連動しない**ため、必ず `親クラス.init(self, ...)` を手動で記述してください。
* **多重継承の制限**
`__includes` には配列形式で複数のクラス（またはテーブル）を指定できますが、複数のクラスが同じ名前のメソッドを持っている場合、記述順によって上書き（優先）されるため衝突に注意が必要です。
* **モジュール管理の原則**
各クラスファイルの末尾には必ず `return クラス名` を記述し、ローカルスコープを汚染しないように `local` 変数としてクラスを受け取る構成（カプセル化）を徹底してください。
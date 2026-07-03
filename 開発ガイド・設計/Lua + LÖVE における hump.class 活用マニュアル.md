# Lua + LÖVE における hump.class 活用マニュアル

LÖVE（Love2D）を用いたゲーム開発において、オブジェクト指向プログラミング（OOP）をシンプルかつ強力に実現するためのライブラリ **hump.class** の仕様書およびテクニック集です。

---

## 1. 基本概要と導入

`hump.class` は、Luaのメタテーブルをラップし、クラスの定義、インスタンス化、継承を直感的な構文で提供する軽量ライブラリです。

### 導入方法

プロジェクトのディレクトリに `class.lua` を配置し、以下のように読み込みます。

```lua
-- main.lua
local Class = require "hump.class"

```

---

## 2. 基本的なクラスの定義とインスタンス化

すべてのクラスの基底となるオブジェクトを作成します。コンストラクタは `init` という名前の関数として定義します。

### 実装例

```lua
local Class = require "hump.class"

-- Vector クラスの定義
local Vector = Class{}

-- コンストラクタ (初期化関数)
function Vector:init(x, y)
    self.x = x or 0
    self.y = y or 0
end

-- メソッドの定義
function Vector:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

-- インスタンス化と利用
local pos = Vector(10, 20)
pos:move(5, -5)
print(pos.x, pos.y) -- 出力: 15, 15

```

---

## 3. クラスの継承（Inheritance）

既存のクラスを拡張して新しいクラスを定義（継承）する場合、`Class{}` の引数に親クラスを渡します。親クラスのメソッドをオーバーライドしたり、親クラスのコンストラクタを呼び出したりすることが可能です。

### 実装例

```lua
local Class = require "hump.class"

-- 基底クラス: Entity
local Entity = Class{}
function Entity:init(x, y)
    self.x = x
    self.y = y
    self.speed = 100
end

function Entity:update(dt)
    self.x = self.x + self.speed * dt
end

-- 派生クラス: Player (Entity を継承)
local Player = Class{
    -- 親クラスを明示的に指定
    __includes = Entity 
}

function Player:init(x, y, name)
    -- 親クラスのコンストラクタを呼び出す
    Entity.init(self, x, y)
    self.name = name
    self.health = 100
end

-- メソッドのオーバーライド
function Player:update(dt)
    -- 親クラスの update メソッドを呼び出しつつ、固有の処理を追加
    Entity.update(self, dt)
    -- プレイヤー固有の処理（例: スタミナ回復など）
end

```

---

## 4. 実践テクニック集

LÖVE で `hump.class` を効率的に運用するための実践的なパターンです。

### テクニック1: 大量のアクター管理（LÖVEのコールバックとの連携）

ゲーム内のオブジェクト（敵、弾など）をクラス化し、テーブルで一括管理する標準的なマネジメントパターンです。

```lua
-- Enemy.lua
local Class = require "hump.class"
local Enemy = Class{}

function Enemy:init(x, y)
    self.x = x
    self.y = y
    self.radius = 15
end

function Enemy:update(dt)
    self.y = self.y + 50 * dt -- 下降する
end

function Enemy:draw()
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Enemy

```

```lua
-- main.lua
local Class = require "hump.class"
local Enemy = require "Enemy"

local enemies = {}

function love.load()
    -- 初期敵キャラクターの生成
    table.insert(enemies, Enemy(100, 0))
    table.insert(enemies, Enemy(300, -50))
end

function love.update(dt)
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy:update(dt)
        
        -- 画面外に出たら削除する判定
        if enemy.y > love.graphics.getHeight() then
            table.remove(enemies, i)
        end
    end
end

function love.draw()
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end
end

```

### テクニック2: ミックスインによる機能のカプセル化

`hump.class` は単一継承ですが、`__includes` に複数のテーブル（またはクラス）を配列形式で渡すことで、複数の機能（ミックスイン）をクラスに組み込むことができます。

```lua
local Class = require "hump.class"

-- 機能コンポーネント（ミックスイン）
local Collidable = {
    checkCollision = function(self, other)
        -- 簡易的な矩形衝突判定
        return self.x < other.x + other.width and
               other.x < self.x + self.width and
               self.y < other.y + other.height and
               other.y < self.y + self.height
    end
}

-- クラス定義時にミックスインを組み込む
local Box = Class{
    __includes = {Collidable} -- 複数の場合は {ParentClass, Mixin1, Mixin2} と記述
}

function Box:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

```

---

## 5. 運用上の注意点とトラブルシューティング

| 現象・問題点 | 原因 | 対策 |
| --- | --- | --- |
| `self` の値が nil になる、または意図しない挙動になる | メソッド呼び出し時にコロン `:` ではなくドット `.` を使用している。 | `object.move()` ではなく `object:move()` と記述する。 |
| 親クラスのメソッドが呼び出せない | `__includes` の指定方法、または親クラスの関数呼び出しの第一引数が漏れている。 | `Parent.method(self, ...)` のように、第一引数に `self` を明示的に渡す。 |
| インスタンス間でテーブル型のプロパティが共有されてしまう | クラス宣言の直下にテーブルを定義している。 | テーブル型のメンバ変数（配列や連想配列など）は、必ず `init` コンストラクタの内部で初期化する。 |

> **警告（テーブル共有の罠）:**
> 以下のようにクラス宣言の直下でテーブルを定義すると、すべてのインスタンスで同じテーブルが参照されます。
> ```lua
> local Inventory = Class{}
> Inventory.items = {} -- NG: すべてのインスタンスで共有される
> 
> function Inventory:init()
>     self.items = {} -- OK: インスタンスごとに独立する
> end
> 
> ```
> 
>
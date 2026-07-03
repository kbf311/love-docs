# Lua + LÖVE 開発を加速させる厳選ライブラリ集

LÖVE（Love2D）は軽量で強力な2Dゲームエンジンですが、標準機能は非常にシンプルです。実用的なゲーム開発においては、拡張ライブラリの導入が必須となります。本書では、プロダクション利用で実績のある高機能・高効率なライブラリをカテゴリ別に厳選し、実装コード例とともに解説します。

---

## 1. クラス・オブジェクト指向 (OOP)

Luaは標準でクラス構文を持ちませんが、メタテーブルを利用してオブジェクト指向を実現します。これを扱いやすくする定番ライブラリです。

### classic

非常に軽量（数十行）でありながら、継承、インスタンス化、クラス検出など必要十分な機能を提供するオブジェクト指向ライブラリです。

* **特徴:** 圧倒的なシンプルさと動作の軽さ。
* **導入方法:** `classic.lua` をプロジェクトに配置。

#### 実装コード例

```lua
local Object = require "classic"

-- クラスの定義
local Point = Object:extend()

function Point:new(x, y)
    self.x = x or 0
    self.y = y or 0
end

function Point:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

-- 継承の例
local Player = Point:extend()

function Player:new(x, y, name)
    Player.super.new(self, x, y) -- 親クラスのコンストラクタ呼び出し
    self.name = name
end

```

---

## 2. イージング・アニメーション (Tweening)

キャラクターの移動、UIのポップアップ、フェードイン・アウトなどの補間処理を滑らかに行うためのライブラリです。

### flux

シンプルかつ強力なイージングライブラリです。複数の変数を同時に変化させたり、処理のチェイン（連続実行）が直感的に書けます。

* **特徴:** 短いコードで複雑なアニメーションフローを制御可能。
* **導入方法:** `flux.lua` をプロジェクトに配置。

#### 実装コード例

```lua
local flux = require "flux"

local player = { x = 100, y = 100, alpha = 1 }

function love.load()
    -- 2秒かけて x=500, y=300 にイージング（BackOut効果）
    -- その後、1秒かけてアルファ値を0にするチェイン処理
    flux.to(player, 2, { x = 500, y = 300 }):ease("backout"):after(player, 1, { alpha = 0 })
end

function love.update(dt)
    flux.update(dt)
end

function love.draw()
    love.graphics.setColor(1, 1, 1, player.alpha)
    love.graphics.rectangle("fill", player.x, player.y, 50, 50)
end

```

---

## 3. 2D物理衝突判定 (Collision Detection)

LÖVEには標準で `love.physics` (Box2D) が組み込まれていますが、トップダウンのRPGやシンプルなプラットフォーマーにはオーバースペックで扱いが難しい場合があります。

### bump.lua

AABB（軸に平行な境界ボックス）に基づいた、グリッドベースのシンプルな衝突判定・応答ライブラリです。

* **特徴:** 物理演算（重力や摩擦の厳密な計算）ではなく、「壁にめり込まない」「滑るように移動する」といったゲーム的な衝突応答を簡単に実装可能。
* **導入方法:** `bump.lua` をプロジェクトに配置。

#### 実装コード例

```lua
local bump = require "bump"
local world

function love.load()
    world = bump.newWorld(64) -- セルサイズ64でワールドを作成
    
    player = { x = 50, y = 50, w = 32, h = 32 }
    wall = { x = 200, y = 50, w = 64, h = 64 }
    
    world:add(player, player.x, player.y, player.w, player.h)
    world:add(wall, wall.x, wall.y, wall.w, wall.h)
end

function love.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("right") then dx = 200 * dt end
    if love.keyboard.isDown("left") then dx = -200 * dt end
    
    if dx ~= 0 or dy ~= 0 then
        -- 衝突を考慮した移動先の座標を計算
        local goalX = player.x + dx
        local goalY = player.y + dy
        local actualX, actualY, cols, cols_len = world:move(player, goalX, goalY)
        
        player.x = actualX
        player.y = actualY
    end
end

```

---

## 4. 画面遷移・シーン管理 (Scene Management)

タイトル画面、ゲーム本編、ゲームオーバー画面などの状態（シーン）を適切に切り替えるためのライブラリです。

### roomer

LÖVEの標準コールバック（`update`, `draw`, `keypressed` など）をシーンごとに独立して管理できるマネージャーです。

* **特徴:** メインファイル（`main.lua`）が肥大化するのを防ぎ、コードのモジュール化を促進。
* **導入方法:** `roomer.lua` をプロジェクトに配置。

#### 実装コード例

##### `main.lua`

```lua
local roomer = require "roomer"

function love.load()
    -- シーンの登録（各シーンは別ファイルで定義）
    roomer.add("title", require "scenes.title")
    roomer.add("game", require "scenes.game")
    
    -- 初期シーンへ遷移
    roomer.switch("title")
end

function love.update(dt) roomer.update(dt) end
function love.draw() roomer.draw() end
function love.keypressed(key) roomer.keypressed(key) end

```

##### `scenes/title.lua` (シーンファイルの例)

```lua
local title = {}

function title:enter()
    -- シーン開始時の処理
end

function title:draw()
    love.graphics.print("TITLE SCREEN - Press Space to Start", 100, 100)
end

function title:keypressed(key)
    if key == "space" then
        local roomer = require "roomer"
        roomer.switch("game")
    end
end

return title

```

---

## 5. タイルマップ読み込み (Map Loading)

オープンソースのマップエディタ「Tiled Map Editor」で作成したデータをLÖVE内に読み込むためのライブラリです。

### STI (Simple Tiled Implementation)

Tiledからエクスポートされた Lua ファイルを直接読み込み、自動で描画・更新を行うデファクトスタンダードなライブラリです。

* **特徴:** レイヤー構造の維持、オブジェクトレイヤーの自動処理、`bump.lua` や `box2d` との連携プラグインが豊富。
* **導入方法:** `sti` フォルダをプロジェクトに配置。

#### 実装コード例

```lua
local sti = require "sti"
local map

function love.load()
    -- TiledからLua形式でエクスポートしたマップファイルを読み込み
    map = sti("assets/maps/level1.lua")
end

function love.update(dt)
    map:update(dt)
end

function love.draw()
    -- マップ全体の描画
    map:draw()
end

```

---

## 6. 入力管理の共通化 (Input Mapping)

キーボード、マウス、ゲームパッド（コントローラー）の入力を抽象化し、一括で管理します。

### baton

キーの複数割り当てや、ゲームパッドのアナログスティックのデッドゾーン処理などを一手に引き受ける入力管理ライブラリです。

* **特徴:** 「左に移動」というアクションに対して、キーボードの `A`、`LeftArrow`、ゲームパッドの `D-pad Left` を同時にバインド可能。
* **導入方法:** `baton.lua` をプロジェクトに配置。

#### 実装コード例

```lua
local baton = require "baton"
local input

function love.load()
    input = baton.new({
        controls = {
            left = { 'key:left', 'key:a', 'axis:leftx-' },
            right = { 'key:right', 'key:d', 'axis:leftx+' },
            action = { 'key:space', 'button:a' }
        },
        pairs = {
            move = { 'left', 'right', 'none', 'none' }
        }
    })
end

function love.update(dt)
    input:update()
    
    -- アクションの判定
    if input:down('left') then
        -- 左移動処理
    end
    
    if input:pressed('action') then
        -- 決定・ジャンプなど（押した瞬間のみ）
    end
end

```

---

## ライブラリ組み合わせのベストプラクティス

小〜中規模のゲームを開発する場合、以下の構成でプロジェクトをスタートすると、堅牢で拡張性の高いアーキテクチャを構築できます。

| カテゴリ | 採用ライブラリ | 役割 |
| --- | --- | --- |
| **基盤・設計** | `classic` | プレイヤー、エネミー、アイテム等の共通クラス化 |
| **進行管理** | `roomer` | タイル画面、ステージ、リザルトの分離 |
| **ステージ構築** | `STI` | マップエディタ連携による生産性向上 |
| **衝突判定** | `bump.lua` | キャラクターと壁、イベントオブジェクトの接触判定 |
| **操作系** | `baton` | キーボード・ゲームパッドのマルチ対応 |
| **演出** | `flux` | UIのアニメーションやカメラシェイクの補間 |
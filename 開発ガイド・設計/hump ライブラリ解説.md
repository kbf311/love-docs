# LÖVE (Love2D) 周辺ライブラリ「hump」徹底解説マニュアル

**hump (Helper Utilities for Massive Progression)** は、LuaおよびLÖVEを用いたゲーム開発において、共通して必要となるゲームループ外の定型処理（オブジェクト指向、カメラ制御、数理ベクトル、タイマー、状態遷移など）を網羅した高機能ユーティリティライブラリです。

各モジュールは完全に独立しているため、必要な機能だけを選んでプロジェクトに導入できます。

---

## 1. 環境構築とインポート

プロジェクトのルートディレクトリに `hump` フォルダを配置し、各モジュールを必要に応じて読み込みます。

```lua
-- 主要モジュールのインポート例
local Class  = require("hump.class")
local Vector = require("hump.vector")
local Timer  = require("hump.timer")
local Camera = require("hump.camera")
local Gamestate = require("hump.gamestate")

```

---

## 2. hump.class（オブジェクト指向）

Lua標準には存在しない「クラス」と「継承」の概念を提供します。インスタンス化、コンストラクタ、多態性（ポリモーフィズム）を簡潔に実装できます。

### 基本定義とインスタンス化

```lua
-- クラスの定義
local Player = Class{}

-- コンストラクタ (__init)
function Player:init(x, y, speed)
    self.x = x
    self.y = y
    self.speed = speed
end

-- メソッドの定義
function Player:move(dt)
    self.x = self.x + self.speed * dt
end

-- インスタンスの生成
local hero = Player(100, 200, 50)

```

### クラスの継承

```lua
-- Playerクラスを継承した特殊クラスの定義
local SpecialPlayer = Class{
    __includes = Player -- 継承元の指定
}

function SpecialPlayer:init(x, y, speed, power)
    -- 親クラスのコンストラクタ呼び出し
    Player.init(self, x, y, speed)
    self.power = power
end

-- メソッドのオーバーライド
function SpecialPlayer:move(dt)
    -- 親クラスのメソッドを呼び出しつつ、固有処理を追加
    Player.move(self, dt * 1.5)
end

```

---

## 3. hump.vector（2次元ベクトル演算）

位置情報、速度、加速度などの2次元座標計算を直感的な演算子オーバーロードで処理します。

### 主な記述法とテクニック

```lua
local v1 = Vector(10, 20)
local v2 = Vector(5, 5)

-- 演算子オーバーロードによる直感的な計算
local v3 = v1 + v2       -- Vector(15, 25)
local v4 = v1 * 2        -- Vector(20, 40)

-- 主要メソッド
local dist  = v1:dist(v2)  -- 2点間の距離
local len   = v1:len()     -- ベクトルの長さ（絶対値）
local norm  = v1:patched() -- 正規化（長さを1にしたベクトルを返す）

```

---

## 4. hump.timer（時間制御とイージング）

一定時間後の処理実行、定期実行、および値のイージング（補間アニメーション）を管理します。ゲーム内のエフェクトやUIアニメーションに必須のモジュールです。

### 基本関数

* `Timer.after(delay, func)` : `delay` 秒後に `func` を1度だけ実行
* `Timer.every(delay, func, count)` : `delay` 秒ごとに `func` を実行（`count` 指定で回数制限可能）
* `Timer.tween(duration, subject, target, method, after)` : 変化率（イージング）を伴う値の補間

### 実装テクニック（LÖVEメインループとの連携）

```lua
function love.load()
    -- 3秒後にプレイヤーの色を赤に変え、その後1秒かけて透明にする
    Timer.after(3, function()
        hero.color = {1, 0, 0, 1}
        Timer.tween(1, hero.color, { [4] = 0 }, 'in-out-quad')
    end)
end

function love.update(dt)
    -- タイマーの更新処理が必須
    Timer.update(dt)
end

```

---

## 5. hump.camera（高機能カメラ制御）

ゲーム画面のスクロール、ズーム、回転、および座標変換（画面座標 $\leftrightarrow$ ワールド座標）を統括します。

### 基本的な組み込み手順

```lua
local cam

function love.load()
    -- 初期位置 (x, y), ズーム倍率, 回転角 でカメラを生成
    cam = Camera(400, 300, 1, 0)
end

function love.draw()
    -- カメラの視界を適用
    cam:attach()
    
        -- ここに描画するオブジェクトはカメラの影響を受ける（ワールド座標系）
        love.graphics.rectangle("fill", hero.x, hero.y, 32, 32)
        
    cam:detach()

    -- ここに描画するオブジェクトは画面に固定される（UI・HUDなど）
    love.graphics.print("Score: 100", 10, 10)
end

```

### スムーズな追従（カメラシューティング）

```lua
function love.update(dt)
    -- プレイヤーの位置へ緩やかにカメラを追従させる（線形補間）
    local targetX, targetY = hero.x, hero.y
    local camX, camY = cam:position()
    
    --  Lerp (線形補間) 計算によるスムーズな移動
    local newX = camX + (targetX - camX) * 0.1
    local newY = camY + (targetY - camY) * 0.1
    
    cam:lookAt(newX, newY)
end

```

---

## 6. hump.gamestate（ゲーム状態管理）

「タイトル画面」「ゲーム本編」「ポーズ画面」「ゲームオーバー」といったゲーム状態（シーン）の遷移をクリーンに分離・管理します。

### ステート（シーン）ファイルの定義

各ステートはLÖVE標準のコールバック関数（`update`, `draw`, `keypressed` 等）に準拠したメソッドを持つテーブルとして定義します。

**`states/menu.lua`（メニュー画面）**

```lua
local menu = {}

function menu:draw()
    love.graphics.printf("PRESS SPACE TO START", 0, 280, 800, "center")
end

function menu:keypressed(key)
    if key == "space" then
        -- ゲーム本編へ遷移
        Gamestate.switch(Game)
    end
end

return menu

```

**`states/game.lua`（ゲーム本編）**

```lua
local game = {}

function game:enter()
    -- ステート開始時に1度だけ呼ばれる初期化処理
    print("Game Started")
end

function game:update(dt)
    -- ゲーム本編の更新ロジック
end

function game:draw()
    -- ゲーム本編の描画ロジック
end

return game

```

### メインファイルでの全統括

`main.lua` 内で `Gamestate.registerEvents()` を呼び出すことで、LÖVEの標準コールバックイベントが、現在アクティブなステートへ自動的にルーティングされます。

```lua
local Gamestate = require("hump.gamestate")
-- 各ステートの読み込み
Menu = require("states/menu")
Game = require("states/game")

function love.load()
    -- LÖVEのイベントハンドラをGamestateに登録
    Gamestate.registerEvents()
    -- 初期ステートへ遷移
    Gamestate.switch(Menu)
end

```

---

## 7. 開発ベストプラクティス（複合テクニック）

### カメラとベクトルの融合

`hump.vector` を使用してカメラのターゲット座標を計算することで、コードの可読性を大幅に向上させます。

```lua
-- プレイヤーの位置ベクトルとマウスの位置ベクトルの中点をカメラの注視点にする
local playerPos = Vector(hero.x, hero.y)
local mousePos  = Vector(love.mouse.getPosition())

-- 画面座標のマウス位置をワールド座標に変換
local mouseWorld = cam:worldCoords(mousePos.x, mousePos.y)
local targetPos  = (playerPos + Vector(mouseWorld.x, mouseWorld.y)) / 2

cam:lookAt(targetPos.x, targetPos.y)

```

### タイマーによるカメラスクリーンシェイク（画面揺らし）

ダメージ演出時などにカメラの座標をタイマーで制御し、即座に減衰させるテクニックです。

```lua
function shakeCamera(intensity, duration)
    local t = 0
    Timer.every(0.05, function()
        local dx = love.math.random(-intensity, intensity)
        local dy = love.math.random(-intensity, intensity)
        cam:lookAt(hero.x + dx, hero.y + dy)
    end, duration / 0.05):after(function()
        -- 終了時に正規の位置へ戻す
        cam:lookAt(hero.x, hero.y)
    end)
end

```
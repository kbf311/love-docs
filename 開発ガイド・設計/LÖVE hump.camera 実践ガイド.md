## Hump.camera 概要

`hump.camera` は、LÖVE（Love2D）で2Dゲームのカメラ機能を簡単に実装するための外部ライブラリ（HUMPツールキットの一部）です。画面のスクロール、ズーム、回転、さらには座標変換（画面座標からワールド座標への変換など）を直感的に制御できます。

---

## 導入と基本セットアップ

### 1. ライブラリの配置

プロジェクトのディレクトリに `camera.lua` を配置します。通常は `libs` などのフォルダに格納します。

```text
my_game/
├── libs/
│   └── camera.lua
├── main.lua
└── conf.lua

```

### 2. 初期化

`main.lua` の `love.load` 内でライブラリを読み込み、インスタンスを生成します。

```lua
local Camera = require "libs.camera"
local cam

function love.load()
    -- カメラの初期位置を (x: 400, y: 300) に設定して生成
    cam = Camera(400, 300)
end

```

---

## 基本操作テクニック

### 1. カメラの移動・追従

カメラの中心座標を変更することで、プレイヤーなどのオブジェクトを追従させます。

```lua
function love.update(dt)
    -- プレイヤーの座標にカメラを滑らかに追従させる（線形補間: Lerp）
    local targetX, targetY = player.x, player.y
    local lerpSpeed = 5 * dt
    
    local camX, camY = cam:position()
    cam:lookAt(
        camX + (targetX - camX) * lerpSpeed,
        camY + (targetY - camY) * lerpSpeed
    )
end

```

### 2. ズーム（拡大・縮小）

`zoom` 属性、または `zoomTo` メソッドを使用して画面の倍率を変更します。

```lua
-- カメラの倍率を2倍にする（拡大）
cam:zoomTo(2)

-- 現在の倍率に特定の値を乗算してズーム（例: マウスホイールでの操作など）
cam:zoom(1.1) 

```

### 3. 回転

`rotate` メソッドを使用して画面全体を回転させます。引数にはラジアン（Radian）を指定します。

```lua
-- カメラを右に45度回転させる
cam:rotate(math.rad(45))

```

---

## 描画処理（Rendering）

カメラの影響を受けるオブジェクトと、UI（ユーザーインターフェース）のように画面に固定するオブジェクトは、描画関数内で明確に分離する必要があります。

```lua
function love.draw()
    -- カメラ空間の開始（この中にある描画処理がスクロールやズームの影響を受ける）
    cam:attach()
        -- ゲームの世界（ワールド空間）のオブジェクトを描画
        love.graphics.rectangle("fill", player.x, player.y, 32, 32)
        love.graphics.circle("line", 500, 500, 100)
    cam:detach()
    -- カメラ空間の終了

    -- 画面固定のUI（スクリーン空間）を描画
    love.graphics.print("Score: " + score, 10, 10)
end

```

---

## 応用・実践テクニック

### 1. マウス座標のワールド変換

画面上のマウス位置（スクリーン座標）を、ゲーム内の実際の位置（ワールド座標）に変換します。クリックした場所への移動や、シューティングゲームの照準などで必須のテクニックです。

```lua
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- スクリーン座標 (x, y) をワールド座標 (worldX, worldY) に変換
        local worldX, worldY = cam:worldCoords(x, y)
        
        -- 変換した座標にエフェクトを生成したり、プレイヤーを移動させる
        spawnClickEffect(worldX, worldY)
    end
end

```

### 2. カメラの移動範囲制限（クランプ）

カメラがマップの境界線（外側）を表示しないように、移動可能な座標を制限します。

```lua
local mapWidth, mapHeight = 2000, 2000

function keepCameraInBounds(camera, minX, minY, maxX, maxY)
    local cx, cy = camera:position()
    
    -- LÖVEの画面サイズを取得して、カメラの可視領域の半分を計算（ズーム未考慮の簡易版）
    local halfW = love.graphics.getWidth() / 2
    local halfH = love.graphics.getHeight() / 2
    
    -- 境界線を超えないようにクランプ
    local clampedX = math.max(minX + halfW, math.min(cx, maxX - halfW))
    local clampedY = math.max(minY + halfH, math.min(cy, maxY - halfH))
    
    camera:lookAt(clampedX, clampedY)
end

function love.update(dt)
    -- プレイヤーへの追従処理の後に実行
    cam:lookAt(player.x, player.y)
    keepCameraInBounds(cam, 0, 0, mapWidth, mapHeight)
end

```

### 3. 画面揺れ（スクリーンシェイク）の効果

ダメージを受けた際などの演出として、カメラの座標にランダムなオフセットを加えます。

```lua
local shakeDuration = 0
local shakeMagnitude = 0

function startShake(duration, magnitude)
    shakeDuration = duration
    shakeMagnitude = magnitude
end

function love.update(dt)
    -- 通常の追従処理
    local targetX, targetY = player.x, player.y
    
    if shakeDuration > 0 then
        -- 残り時間を減算
        shakeDuration = shakeDuration - dt
        -- ランダムなオフセットを計算
        local offsetX = love.math.random(-shakeMagnitude, shakeMagnitude)
        local offsetY = love.math.random(-shakeMagnitude, shakeMagnitude)
        
        targetX = targetX + offsetX
        targetY = targetY + offsetY
    end
    
    cam:lookAt(targetX, targetY)
end

```

---

## 主要APIリファレンス一覧

| メソッド / 属性 | 説明 |
| --- | --- |
| `Camera(x, y, zoom, rot)` | 新しいカメラインスタンスを生成。初期位置、ズーム倍率、回転角を指定可能。 |
| `cam:lookAt(x, y)` | カメラの中心座標を `(x, y)` に移動。 |
| `cam:move(dx, dy)` | 現在の位置から `(dx, dy)` だけ相対的にカメラを移動。 |
| `cam:position()` | 現在のカメラの中心座標 `x, y` を返す。 |
| `cam:zoomTo(zoom)` | 指定した倍率にズームを設定（1が標準）。 |
| `cam:zoom(factor)` | 現在の倍率に `factor` を乗算。 |
| `cam:rotate(angle)` | 指定したラジアンだけカメラを回転。 |
| `cam:attach()` | カメラの座標系を適用（描画開始）。 |
| `cam:detach()` | カメラの座標系を解除（描画終了）。 |
| `cam:worldCoords(x, y)` | スクリーン座標（画面）をワールド座標（ゲーム内）に変換。 |
| `cam:cameraCoords(x, y)` | ワールド座標（ゲーム内）をスクリーン座標（画面）に変換。 |